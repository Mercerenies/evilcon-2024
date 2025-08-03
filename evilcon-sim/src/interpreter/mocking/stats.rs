
use crate::interpreter::class::{Class, ClassBuilder};
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::method::{Method, MethodArgs};
use crate::interpreter::value::Value;
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::{expect_int, expect_string};
use crate::ast::identifier::Identifier;
use super::stats_panel::DESTINY_SONG_LIMIT;

use std::sync::Arc;
use std::collections::HashMap;

pub(super) const CARD_META_LEVEL: &str = "LEVEL";
pub(super) const CARD_META_MORALE: &str = "MORALE";

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
    basic_set_stat("set_evil_points", "evil_points", state, args)?;
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("add_evil_points"), Method::rust_static_method("add_evil_points", |state, args| {
    basic_add_stat("add_evil_points", "evil_points", state, args)?;
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("set_fort_defense"), Method::rust_static_method("set_fort_defense", |state, args| {
    let res = basic_set_stat("set_fort_defense", "fort_defense", state, args)?;
    if res.new_value <= 0 {
      send_endgame_signal(state, res.playing_field, other_player(res.player)?)?;
    }
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("add_fort_defense"), Method::rust_static_method("add_fort_defense", |state, args| {
    let res = basic_add_stat("add_fort_defense", "fort_defense", state, args)?;
    if res.new_value <= 0 {
      send_endgame_signal(state, res.playing_field, other_player(res.player)?)?;
    }
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("set_destiny_song"), Method::rust_static_method("set_destiny_song", |state, args| {
    let res = basic_set_stat("set_destiny_song", "destiny_song", state, args)?;
    if res.new_value >= DESTINY_SONG_LIMIT {
      send_endgame_signal(state, res.playing_field, res.player)?;
    }
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("add_destiny_song"), Method::rust_static_method("add_destiny_song", |state, args| {
    let res = basic_add_stat("add_destiny_song", "destiny_song", state, args)?;
    if res.new_value >= DESTINY_SONG_LIMIT {
      send_endgame_signal(state, res.playing_field, res.player)?;
    }
    Ok(Value::Null)
  }));
  methods.insert(Identifier::new("set_level"), Method::rust_static_method("set_level", set_card_level));
  methods.insert(Identifier::new("add_level"), Method::rust_static_method("add_level", add_card_level));
  methods.insert(Identifier::new("set_morale"), Method::rust_static_method("set_morale", set_card_morale));
  methods.insert(Identifier::new("add_morale"), Method::rust_static_method("add_morale", add_card_morale));

  ClassBuilder::default()
    .name("Stats")
    .parent(node)
    .constants(constants)
    .methods(methods)
    .build()
}

fn basic_set_stat(func_name: &str, stat_name: &str, state: &mut EvaluatorState, args: MethodArgs) -> Result<BasicStatResult, EvalError> {
  let (playing_field, player, new_value) = args.expect_three_args(func_name)?;
  let stats = state.call_function_on(&playing_field, "get_stats", vec![player.clone()])?;
  stats.set_value(stat_name, new_value.clone(), state.superglobal_state())?;
  Ok(BasicStatResult {
    new_value: expect_int(&new_value)?,
    playing_field,
    player,
  })
}

fn basic_add_stat(func_name: &str, stat_name: &str, state: &mut EvaluatorState, args: MethodArgs) -> Result<BasicStatResult, EvalError> {
  let (playing_field, player, delta_value) = args.expect_three_args(func_name)?;
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

fn set_card_level(state: &mut EvaluatorState, mut args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(3, 4, "set_level")?;
  // Don't need the last arg, so ignore it if present.
  if args.len() == 4 {
    args.0.pop();
  }
  let [_, card, new_value] = args.try_into().unwrap();
  let new_value = i64::max(0, expect_int(&new_value)?);
  let metadata = card.get_value("metadata", state.superglobal_state())?;
  metadata.set_index(Value::from(CARD_META_LEVEL), Value::from(new_value))?;
  Ok(Value::Null)
}

fn add_card_level(state: &mut EvaluatorState, mut args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(3, 4, "add_level")?;
  // Don't need the last arg, so ignore it if present.
  if args.len() == 4 {
    args.0.pop();
  }
  let [_, card, delta_value] = args.try_into().unwrap();
  let delta_value = i64::max(0, expect_int(&delta_value)?);
  let metadata = card.get_value("metadata", state.superglobal_state())?;
  let old_value = expect_int(&metadata.get_index(Value::from(CARD_META_LEVEL), state)?)?;
  let new_value = i64::max(0, old_value + delta_value);
  metadata.set_index(Value::from(CARD_META_LEVEL), Value::from(new_value))?;
  Ok(Value::Null)
}

fn set_card_morale(state: &mut EvaluatorState, mut args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(3, 4, "set_morale")?;
  // Don't need the last arg, so ignore it if present.
  if args.len() == 4 {
    args.0.pop();
  }
  let [playing_field, card, new_value] = args.try_into().unwrap();
  let new_value = i64::max(0, expect_int(&new_value)?);
  let metadata = card.get_value("metadata", state.superglobal_state())?;
  metadata.set_index(Value::from(CARD_META_MORALE), Value::from(new_value))?;
  do_morale_check(state, playing_field, card)?;
  Ok(Value::Null)
}

fn add_card_morale(state: &mut EvaluatorState, mut args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(3, 4, "add_morale")?;
  // Don't need the last arg, so ignore it if present.
  if args.len() == 4 {
    args.0.pop();
  }
  let [playing_field, card, delta_value] = args.try_into().unwrap();
  let delta_value = i64::max(0, expect_int(&delta_value)?);
  let metadata = card.get_value("metadata", state.superglobal_state())?;
  let old_value = expect_int(&metadata.get_index(Value::from(CARD_META_LEVEL), state)?)?;
  let new_value = i64::max(0, old_value + delta_value);
  metadata.set_index(Value::from(CARD_META_MORALE), Value::from(new_value))?;
  do_morale_check(state, playing_field, card)?;
  Ok(Value::Null)
}

fn do_morale_check(state: &EvaluatorState, playing_field: Value, card: Value) -> Result<(), EvalError> {
  let metadata = card.get_value("metadata", state.superglobal_state())?;
  let curr_morale = expect_int(&metadata.get_index(Value::from(CARD_META_MORALE), state)?)?;
  if curr_morale <= 0 {
    let card_type = card.get_value("card_type", state.superglobal_state())?;
    state.call_function_on(&card_type, "on_pre_expire", vec![playing_field.clone(), card.clone()])?;
    let curr_morale = expect_int(&metadata.get_index(Value::from(CARD_META_MORALE), state)?)?;
    if curr_morale <= 0 {
      state.call_function_on(&card_type, "on_expire", vec![playing_field.clone(), card.clone()])?;
      let card_game_api = get_card_game_api(state)?;
      state.call_function_on(&card_game_api, "destroy_card", vec![playing_field, card])?;
    }
  }
  Ok(())
}

fn get_card_game_api(state: &EvaluatorState) -> Result<Value, EvalError> {
  state.superglobal_state().get_var("CardGameApi")
    .map(|x| x.clone().into())
    .ok_or_else(|| EvalError::UndefinedVariable(String::from("CardGameApi")))
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
