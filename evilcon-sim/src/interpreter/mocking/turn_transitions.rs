
use crate::interpreter::class::{Class, ClassBuilder};
use crate::interpreter::method::{Method, MethodArgs};
use crate::interpreter::error::EvalError;
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::value::Value;
use crate::interpreter::operator::expect_int;
use crate::ast::identifier::Identifier;
use super::playing_field::ENDGAME_VARIABLE;

use std::sync::Arc;
use std::collections::HashMap;

pub const TURN_TRANSITIONS_RES_PATH: &str = "res://card_game/playing_field/util/card_game_turn_transitions.gd";
pub const PLAY_FULL_GAME_METHOD: &str = "play_full_game";

const STATS_CALCULATOR: &str = "StatsCalculator";
const CARD_GAME_API: &str = "CardGameApi";
const CARD_GAME_PHASES: &str = "CardGamePhases";
const CARD_PLAYER_BOTTOM: &str = "BOTTOM";
const CARD_PLAYER_TOP: &str = "TOP";

pub(super) fn turn_transitions_class(node: Arc<Class>) -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::new(PLAY_FULL_GAME_METHOD), Method::rust_static_method(PLAY_FULL_GAME_METHOD, play_full_game));

  ClassBuilder::default()
    .name("CardGameTurnTransitions")
    .parent(node)
    .methods(methods)
    .build()
}


// NOTE: Intentional divergence from GDScript. The GDScript method
// takes one argument: playing_field. This method takes a second
// argument, indicating the max turn count, so we can prevent infinite
// loops.
fn play_full_game(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  args.expect_arity_within(1, 2, "play_full_game")?;
  let playing_field;
  let max_turns;
  match args.len() {
    1 => {
      [playing_field] = args.try_into().unwrap();
      max_turns = None;
    }
    2 => {
      let max_turns_n;
      [playing_field, max_turns_n] = args.try_into().unwrap();
      let max_turns_n: usize = expect_int("play_full_game", &max_turns_n)?
        .try_into()
        .map_err(|_| EvalError::domain_error("Expected unsigned int"))?;
      max_turns = Some(max_turns_n);
    }
    _ => {
      unreachable!("Unreachable statement; just checked arity between 1 and 2");
    }
  };
  draw_initial_hand(state, &playing_field, CARD_PLAYER_BOTTOM)?;
  draw_initial_hand(state, &playing_field, CARD_PLAYER_TOP)?;
  let card_game_phases = get_global(state, CARD_GAME_PHASES)?;
  let mut turn_iter = 0;
  while !check_for_endgame(state, &playing_field)? {
    state.call_function_on(&card_game_phases, "start_of_full_turn", vec![playing_field.clone()])?;
    run_turn_for(state, &playing_field, CARD_PLAYER_BOTTOM)?;
    run_turn_for(state, &playing_field, CARD_PLAYER_TOP)?;
    state.call_function_on(&card_game_phases, "end_of_full_turn", vec![playing_field.clone()])?;
    turn_iter += 1;
    if let Some(max_turns) = max_turns && turn_iter >= max_turns {
      return Err(EvalError::LoopLimitExceeded { limit: max_turns });
    }
  }
  // In Godot, this method never returns (it awaits a signal that will
  // never fire). We just return null here, since we don't use signals
  // in this implementation.
  Ok(Value::Null)
}

fn draw_initial_hand(state: &EvaluatorState, playing_field: &Value, player: &str) -> Result<(), EvalError> {
  let stats_calculator = get_global(state, STATS_CALCULATOR)?;
  let card_game_api = get_global(state, CARD_GAME_API)?;
  let hand_limit = expect_int("draw_initial_hand",
                              &state.call_function_on(&stats_calculator,
                                                      "get_hand_limit",
                                                      vec![playing_field.clone(), Value::from(player)])?)?;
  state.call_function_on(&card_game_api,
                         "draw_cards",
                         vec![playing_field.clone(), Value::from(player), Value::from(hand_limit)])?;
  Ok(())
}

fn run_turn_for(state: &EvaluatorState, playing_field: &Value, player: &str) -> Result<(), EvalError> {
  let card_game_phases = get_global(state, CARD_GAME_PHASES)?;
  playing_field.set_value("turn_player", Value::from(player), state.superglobal_state())?;
  state.call_function_on(&card_game_phases, "draw_phase", vec![playing_field.clone(), Value::from(player)])?;
  state.call_function_on(&card_game_phases, "attack_phase", vec![playing_field.clone(), Value::from(player)])?;
  state.call_function_on(&card_game_phases, "morale_phase", vec![playing_field.clone(), Value::from(player)])?;
  state.call_function_on(&card_game_phases, "standby_phase", vec![playing_field.clone(), Value::from(player)])?;

  // Player agent turn
  let player_agent = state.call_function_on(playing_field, "player_agent", vec![Value::from(player)])?;
  state.call_function_on(&player_agent, "run_one_turn", vec![playing_field.clone()])?;

  state.call_function_on(&card_game_phases, "end_phase", vec![playing_field.clone(), Value::from(player)])?;
  Ok(())
}

fn check_for_endgame(state: &EvaluatorState, playing_field: &Value) -> Result<bool, EvalError> {
  let endgame_value = playing_field.get_value(ENDGAME_VARIABLE, state.superglobal_state())?;
  Ok(matches!(endgame_value, Value::String(_)))
}

fn get_global(state: &EvaluatorState, name: &str) -> Result<Value, EvalError> {
  state.superglobal_state().get_var(name)
    .map(|x| x.clone().into())
    .ok_or_else(|| EvalError::UndefinedVariable(name.to_string()))
}
