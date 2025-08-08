
//! Mocked classes that are *not* necessarily for bootstrapping.
//!
//! Interpreter-critical classes like `Array` belong in
//! `bootstrapping.rs`, not here.

mod card_strip;
mod playing_field;
mod randomness;
mod stats;
mod stats_panel;
mod turn_transitions;

pub mod codex;

pub use playing_field::{ENDGAME_VARIABLE, SECOND_PLAYER_FORT_ADVANTAGE};
pub use turn_transitions::{PLAY_FULL_GAME_METHOD, TURN_TRANSITIONS_RES_PATH};
pub use stats_panel::DEFAULT_FORT_DEFENSE;

pub const PLAYING_FIELD_RES_PATH: &str = "res://card_game/playing_field/playing_field.gd";

use super::class::{Class, ClassBuilder};
use super::class::constant::LazyConst;
use super::value::{Value, SimpleValue};
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

  // Promise
  let promise = dummy_class(); // I hope this one is unused...
  superglobals.bind_class(Identifier::new("Promise"), Arc::new(promise));

  // PlayingField
  let playing_field = playing_field::playing_field_class(Arc::clone(&node));
  superglobals.add_file(ResourcePath::new(PLAYING_FIELD_RES_PATH), Arc::new(playing_field));

  // CardStrip
  let card_strip_class = card_strip::card_strip_class(Arc::clone(&node));
  superglobals.add_file(ResourcePath::new(card_strip::CARD_STRIP_RES_PATH), Arc::new(card_strip_class));
  let card_strip_tscn = card_strip::card_strip_tscn_class();
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/card_strip/card_strip.tscn"), Arc::new(card_strip_tscn));

  // CardIcon
  let card_icon_gd = dummy_class();
  superglobals.add_file(ResourcePath::new("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd"), Arc::new(card_icon_gd));

  // CardContainer (.tscn only; we parse the real CardContainer.gd)
  let card_container_tscn = dummy_class();
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/card_container/card_container.tscn"), Arc::new(card_container_tscn));

  // Randomness
  let randomness = randomness::randomness_class(Arc::clone(&superglobals.bootstrapped_classes().refcounted()));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/randomness.gd"), Arc::new(randomness));

  // GameStatsPanel
  let game_stats_panel_gd = stats_panel::game_stats_panel_class(Arc::clone(&node));
  superglobals.add_file(ResourcePath::new(stats_panel::STATS_PANEL_RES_PATH), Arc::new(game_stats_panel_gd));
  let game_stats_panel_tscn = dummy_class();
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/game_stats_panel/game_stats_panel.tscn"), Arc::new(game_stats_panel_tscn));

  // Stats
  let stats_gd = stats::stats_static_class(Arc::clone(&node));
  let stats_gd = Arc::new(stats_gd);
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/util/stats.gd"), stats_gd.clone());
  superglobals.bind_class(Identifier::new("Stats"), stats_gd.clone());

  // CardGameTurnTransitions
  let turn_transitions = turn_transitions::turn_transitions_class(Arc::clone(&node));
  let turn_transitions = Arc::new(turn_transitions);
  superglobals.add_file(ResourcePath::new(turn_transitions::TURN_TRANSITIONS_RES_PATH), Arc::clone(&turn_transitions));
  superglobals.bind_class(Identifier::new("CardGameTurnTransitions"), turn_transitions);

  // InputBlockAnimation placeholder (needs to inherit from Object so we get free())
  let input_block_animation = ClassBuilder::default().parent(Arc::clone(&superglobals.bootstrapped_classes().object())).build();
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/animation/input_block_animation.gd"), Arc::new(input_block_animation));

  // A bunch of placeholders that CardGameApi needs :)
  superglobals.add_file(ResourcePath::new("res://card_game/playing_card/hidden_card_display/hidden_card_display.tscn"), Arc::new(dummy_class()));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_card/deck_card_display/deck_card_display.tscn"), Arc::new(dummy_class()));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/animation/puff_of_smoke/puff_of_smoke_animation.gd"), Arc::new(dummy_class()));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/animation/musical_note/musical_note_animation.gd"), Arc::new(dummy_class()));
}

pub fn bind_mocked_constants(superglobals: &mut SuperglobalState) {
  // PI
  superglobals.bind_var(Identifier::new("PI"), SimpleValue::from(PI));
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
  superglobals.define_func(Identifier::new("fmod"), Method::rust_method("fmod", binary_float_function("fmod", f64::rem)));
  superglobals.define_func(Identifier::new("min"), Method::rust_method("min", binary_float_function("min", f64::min)));
  superglobals.define_func(Identifier::new("max"), Method::rust_method("max", binary_float_function("max", f64::max)));
  superglobals.define_func(Identifier::new("mini"), Method::rust_method("mini", binary_int_function("mini", i64::min)));
  superglobals.define_func(Identifier::new("maxi"), Method::rust_method("maxi", binary_int_function("maxi", i64::max)));
  superglobals.define_func(Identifier::new("clampi"), Method::rust_method("clampi", clampi_function));

  // float cast
  superglobals.define_func(Identifier::new("float"), Method::rust_method("float", float_cast_function));
}

fn node_class(object: Arc<Class>) -> Class {
  ClassBuilder::default()
    .name("Node")
    .parent(object)
    .build()
}

fn popup_text_class(node: Arc<Class>) -> Class {
  const CONST_NAMES: [&str; 6] = ["NO_TARGET", "BLOCKED", "CLOWNED", "DEMONED", "ROBOTED", "WILDED"];
  let mut constants = HashMap::new();
  for const_name in CONST_NAMES {
    constants.insert(Identifier::new(const_name), LazyConst::resolved(SimpleValue::from("UNUSED CONSTANT")));
  }
  ClassBuilder::default()
    .name("PopupText")
    .parent(node)
    .constants(Arc::new(constants))
    .build()
}

/// A dummy class that is intended to go completely unused. The
/// properties of this class are not specified, other than the fact
/// that it exists.
fn dummy_class() -> Class {
  Class::default()
}

fn preload_method(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity(1, "preload")?;
  let [arg] = args.0.try_into().unwrap();
  let arg = expect_string(&arg)?;
  let class = state.get_file(arg)
    .ok_or_else(|| EvalError::UndefinedClass(arg.to_owned()))?;
  Ok(Value::ClassRef(class))
}

fn len_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let arg = args.expect_one_arg("len")?;
  match arg {
    Value::ArrayRef(arr) => Ok(Value::Int(arr.borrow().len() as i64)),
    Value::DictRef(arr) => Ok(Value::Int(arr.borrow().len() as i64)),
    Value::String(s) => Ok(Value::Int(s.len() as i64)),
    _ => Err(EvalError::type_error("array, string, or dict", arg)),
  }
}

fn range_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(1, 3, "range")?;
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
  tracing::debug!(gd_output = true, "{}", args.0.into_iter().map(prettify).join(""));
  Ok(Value::Null)
}

fn push_error_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  tracing::error!(gd_output = true, "{}", args.0.into_iter().map(prettify).join(""));
  Ok(Value::Null)
}

fn push_warning_method(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  tracing::warn!(gd_output = true, "{}", args.0.into_iter().map(prettify).join(""));
  Ok(Value::Null)
}

fn prettify(value: Value) -> String {
  if let Value::String(s) = value {
    s
  } else {
    value.to_string()
  }
}

fn clampi_function(_: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity(3, "clampi")?;
  let [a, b, c] = args.try_into().unwrap();
  let a = expect_int_loosely(&a)?;
  let b = expect_int_loosely(&b)?;
  let c = expect_int_loosely(&c)?;
  let result_value = if a < b { b } else if a > c { c } else { a };
  Ok(Value::Int(result_value))
}

fn binary_int_function<F, R>(fn_name: &str, func: F) -> impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + 'static
where F: Fn(i64, i64) -> R + 'static,
      Value: From<R> {
  let fn_name = fn_name.to_owned();
  move |_, args| {
    let (a, b) = args.expect_two_args(&fn_name)?;
    Ok(func(expect_int_loosely(&a)?, expect_int_loosely(&b)?).into())
  }
}

fn binary_float_function<F, R>(fn_name: &str, func: F) -> impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + 'static
where F: Fn(f64, f64) -> R + 'static,
      Value: From<R> {
  let fn_name = fn_name.to_owned();
  move |_, args| {
    let (a, b) = args.expect_two_args(&fn_name)?;
    Ok(func(expect_float_loosely(&a)?, expect_float_loosely(&b)?).into())
  }
}

fn float_cast_function(_state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let arg = args.expect_one_arg("float")?;
  match arg {
    Value::Float(f) => Ok(Value::from(*f)),
    Value::Int(i) => Ok(Value::from(i as f64)),
    Value::Bool(b) => Ok(Value::from(if b { 1.0 } else { 0.0 })),
    Value::String(s) => {
      let f = s.parse::<f64>().map_err(|_| EvalError::NumberParseError(s.to_owned()))?;
      Ok(Value::from(f))
    }
    arg => Err(EvalError::type_error("number, string, or bool", arg)),
  }
}
