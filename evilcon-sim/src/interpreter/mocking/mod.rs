
//! Mocked classes that are *not* necessarily for bootstrapping.
//!
//! Interpreter-critical classes like `Array` belong in
//! `bootstrapping.rs`, not here.

mod playing_field;

use super::class::Class;
use super::class::constant::LazyConst;
use super::value::Value;
use super::eval::{SuperglobalState, EvaluatorState};
use super::method::{MethodArgs, Method};
use super::error::EvalError;
use super::operator::{expect_string, expect_int_loosely, expect_float_loosely};
use crate::ast::identifier::{Identifier, ResourcePath};

use itertools::Itertools;

use std::sync::Arc;
use std::collections::HashMap;
use std::f64::consts::PI;
use std::ops::Rem;

pub fn bind_mocked_classes(superglobals: &mut SuperglobalState) {
  // Node
  let node = node_class(Arc::clone(superglobals.bootstrapped_classes().object()));
  let node = Arc::new(node);
  superglobals.bind_class(Identifier::new("Node"), Arc::clone(&node));

  // PopupText
  let popup_text = popup_text_class(Arc::clone(&node));
  let popup_text = Arc::new(popup_text);
  superglobals.bind_class(Identifier::new("PopupText"), Arc::clone(&popup_text));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/util/popup_text.gd"), popup_text);

  // CardMovingAnimation
  let card_moving_animation = dummy_class(); // Should be entirely unused.
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/animation/card_moving/card_moving_animation.gd"), Arc::new(card_moving_animation));

  // PlayingField
  let playing_field = playing_field::playing_field_class(Arc::clone(&node));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/playing_field.gd"), Arc::new(playing_field));

  // Randomness
  let randomness = playing_field::randomness_class(Arc::clone(&superglobals.bootstrapped_classes().refcounted()));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/randomness.gd"), Arc::new(randomness));
}

pub fn bind_mocked_constants(superglobals: &mut SuperglobalState) {
  // PI
  superglobals.bind_var(Identifier::new("PI"), Value::from(PI));
}

pub fn bind_mocked_methods(superglobals: &mut SuperglobalState) {
  // load and preload (aliases)
  superglobals.define_func(Identifier::new("load"), Method::rust_method("load", preload_method));
  superglobals.define_func(Identifier::new("preload"), Method::rust_method("preload", preload_method));

  // len
  superglobals.define_func(Identifier::new("len"), Method::rust_method("len", len_method));

  // range
  superglobals.define_func(Identifier::new("range"), Method::rust_method("range", range_method));

  // print, push_error, push_warning
  superglobals.define_func(Identifier::new("print"), Method::rust_method("print", print_method));
  superglobals.define_func(Identifier::new("push_error"), Method::rust_method("push_error", push_error_method));
  superglobals.define_func(Identifier::new("push_warning"), Method::rust_method("push_warning", push_warning_method));

  // Misc math operators (Note: min, max, and company are vararg, but
  // we implement them as binary here)
  superglobals.define_func(Identifier::new("fmod"), Method::rust_method("fmod", binary_float_function(f64::rem)));
  superglobals.define_func(Identifier::new("min"), Method::rust_method("min", binary_float_function(f64::min)));
  superglobals.define_func(Identifier::new("max"), Method::rust_method("max", binary_float_function(f64::max)));
  superglobals.define_func(Identifier::new("mini"), Method::rust_method("mini", binary_int_function(i64::min)));
  superglobals.define_func(Identifier::new("maxi"), Method::rust_method("maxi", binary_int_function(i64::max)));
}

fn node_class(object: Arc<Class>) -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Node")),
    parent: Some(object),
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn popup_text_class(node: Arc<Class>) -> Class {
  const CONST_NAMES: [&str; 6] = ["NO_TARGET", "BLOCKED", "CLOWNED", "DEMONED", "ROBOTED", "WILDED"];
  let mut constants = HashMap::new();
  for const_name in CONST_NAMES {
    constants.insert(Identifier::new(const_name), LazyConst::resolved(Value::from("UNUSED CONSTANT")));
  }
  let methods = HashMap::new();
  Class {
    name: Some(String::from("PopupText")),
    parent: Some(node),
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

/// A dummy class that is intended to go completely unused. The
/// properties of this class are not specified, other than the fact
/// that it exists.
fn dummy_class() -> Class {
  Class {
    name: None,
    parent: None,
    constants: Arc::new(HashMap::new()),
    instance_vars: vec![],
    methods: HashMap::new(),
  }
}

fn preload_method(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity(1)?;
  let [arg] = args.0.try_into().unwrap();
  let arg = expect_string(&arg)?;
  let class = state.get_file(arg)
    .ok_or_else(|| EvalError::UndefinedClass(arg.to_owned()))?;
  Ok(Value::ClassRef(class))
}

fn len_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let arg = args.expect_one_arg()?;
  match arg {
    Value::ArrayRef(arr) => Ok(Value::Int(arr.borrow().len() as i64)),
    Value::DictRef(arr) => Ok(Value::Int(arr.borrow().len() as i64)),
    Value::String(s) => Ok(Value::Int(s.len() as i64)),
    _ => Err(EvalError::type_error("array, string, or dict", arg)),
  }
}

fn range_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(1, 3)?;
  let (begin, end, step) = match args.len() {
    1 => {
      (0, expect_int_loosely(&args[0])?, 1)
    }
    2 => {
      (expect_int_loosely(&args[0])?, expect_int_loosely(&args[1])?, 1)
    }
    3 => {
      (expect_int_loosely(&args[0])?, expect_int_loosely(&args[1])?, expect_int_loosely(&args[2])?)
    }
    _ => unreachable!(),
  };
  if step == 0 {
    return Err(EvalError::domain_error("step argument cannot be zero"));
  }
  let arr = if step > 0 {
    (begin..end).step_by(step as usize).map(Value::from).collect()
  } else {
    (end+1..=begin).rev().step_by((-step) as usize).map(Value::from).collect()
  };
  Ok(Value::new_array(arr))
}

fn print_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  println!("{}", args.0.into_iter().join(""));
  Ok(Value::Null)
}

fn push_error_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  eprintln!("ERROR: {}", args.0.into_iter().join(""));
  Ok(Value::Null)
}

fn push_warning_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  eprintln!("WARNING: {}", args.0.into_iter().join(""));
  Ok(Value::Null)
}

fn binary_int_function<F, R>(func: F) -> impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + 'static
where F: Fn(i64, i64) -> R + 'static,
      Value: From<R> {
  move |_, args| {
    let (a, b) = args.expect_two_args()?;
    Ok(func(expect_int_loosely(&a)?, expect_int_loosely(&b)?).into())
  }
}

fn binary_float_function<F, R>(func: F) -> impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + 'static
where F: Fn(f64, f64) -> R + 'static,
      Value: From<R> {
  move |_, args| {
    let (a, b) = args.expect_two_args()?;
    Ok(func(expect_float_loosely(&a)?, expect_float_loosely(&b)?).into())
  }
}
