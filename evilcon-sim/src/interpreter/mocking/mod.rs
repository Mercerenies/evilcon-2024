
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
use super::operator::expect_string;
use crate::ast::identifier::{Identifier, ResourcePath};

use std::sync::Arc;
use std::collections::HashMap;

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

pub fn bind_mocked_methods(superglobals: &mut SuperglobalState) {
  // load and preload (aliases)
  superglobals.define_func(Identifier::new("load"), Method::rust_method("load", preload_method));
  superglobals.define_func(Identifier::new("preload"), Method::rust_method("preload", preload_method));
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
