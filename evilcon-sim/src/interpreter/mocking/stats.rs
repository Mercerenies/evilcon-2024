
use crate::interpreter::class::{Class, ClassBuilder, InstanceVar, ProxyVar};
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::method::{Method, MethodArgs};
use crate::interpreter::value::Value;
use crate::interpreter::eval::{SuperglobalState, EvaluatorState};
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::{expect_int, expect_string};
use crate::ast::expr::Expr;
use crate::ast::identifier::Identifier;
use crate::util::clamp;

use std::sync::Arc;
use std::collections::HashMap;

#[derive(Debug, Clone)]
struct BasicStatResult {
  new_value: i64,
  playing_field: Value,
  player: Value,
}

const TARGET_TEXT_VALUES: &[(&str, &str)] = &[
  ("NO_TARGET", "No Target!"),
  ("BLOCKED", "Blocked!"),
  ("CLOWNED", "Clowned!"),
  ("DEMONED", "Bedeviled!"),
  ("ROBOTED", "Upgraded!"),
];

pub(super) fn stats_static_class(node: Arc<Class>) -> Class {
  let mut constants = HashMap::new();
  constants.insert(Identifier::new("NumberAnimation"), LazyConst::null());
  constants.insert(Identifier::new("GameStatsDict"), LazyConst::null());
  constants.insert(Identifier::new("CARD_MULTI_UI_OFFSET"), LazyConst::null());
  for (var_prefix, str_value) in TARGET_TEXT_VALUES {
    constants.insert(Identifier::new(format!("{var_prefix}_TEXT")), LazyConst::resolved(Value::from(*str_value)));
    constants.insert(Identifier::new(format!("{var_prefix}_COLOR")), LazyConst::null());
  }

  let mut methods = HashMap::new();
  methods.insert(Identifier::new("play_animation_for_stat_change"), Method::static_noop());
  methods.insert(Identifier::new("show_text"), Method::static_noop());
  methods.insert(Identifier::new("set_evil_points"), Method::rust_static_method("set_evil_points", |state, args| {
    basic_set_stat("evil_points", state, args)?;
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("add_evil_points"), Method::rust_static_method("add_evil_points", |state, args| {
    basic_add_stat("evil_points", state, args)?;
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("set_fort_defense"), Method::rust_static_method("set_fort_defense", |state, args| {
    let res = basic_set_stat("fort_defense", state, args)?;
    if res.new_value <= 0 {
      send_endgame_signal(state, res.playing_field, other_player(res.player)?)?;
    }
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("add_fort_defense"), Method::rust_static_method("add_fort_defense", |state, args| {
    let res = basic_add_stat("fort_defense", state, args)?;
    if res.new_value <= 0 {
      send_endgame_signal(state, res.playing_field, other_player(res.player)?)?;
    }
    Ok(Value::Null)
  }));

  ClassBuilder::default()
    .name("Stats")
    .parent(node)
    .constants(constants)
    .methods(methods)
    .build()
}

fn basic_set_stat(stat_name: &str, state: &mut EvaluatorState, args: MethodArgs) -> Result<BasicStatResult, EvalError> {
  let (playing_field, player, new_value) = args.expect_three_args()?;
  let stats = state.call_function_on(&playing_field, "get_stats", vec![player.clone()])?;
  stats.set_value(stat_name, new_value.clone(), state.superglobal_state())?;
  Ok(BasicStatResult {
    new_value: expect_int(&new_value)?,
    playing_field,
    player,
  })
}

fn basic_add_stat(stat_name: &str, state: &mut EvaluatorState, args: MethodArgs) -> Result<BasicStatResult, EvalError> {
  let (playing_field, player, delta_value) = args.expect_three_args()?;
  let delta_value = expect_int(&delta_value)?;
  let stats = state.call_function_on(&playing_field, "get_stats", vec![player.clone()])?;
  let old_value = expect_int(&stats.get_value(stat_name, state.superglobal_state())?)?;
  stats.set_value(stat_name, Value::from(old_value + delta_value), state.superglobal_state())?;
  Ok(BasicStatResult {
    new_value: old_value + delta_value,
    playing_field,
    player,
  })
}

fn send_endgame_signal(state: &EvaluatorState, playing_field: Value, winning_player: Value) -> Result<(), EvalError> {
  state.call_function_on(&playing_field, "end_game", vec![winning_player])?;
  Ok(())
}

fn other_player(player: Value) -> Result<Value, EvalError> {
  let player = expect_string(&player)?;
  match player {
    "TOP" => Ok(Value::from("BOTTOM")),
    "BOTTOM" => Ok(Value::from("TOP")),
    _ => Err(EvalError::domain_error("Bad card player")),
  }
}
