
pub mod code;
pub mod deck;
pub mod genetic;

pub use deck::{Deck, CardId, DECK_SIZE};

use crate::interpreter::eval::{SuperglobalState, EvaluatorState};
use crate::interpreter::mocking::{PLAYING_FIELD_RES_PATH, ENDGAME_VARIABLE, TURN_TRANSITIONS_RES_PATH,
                                  DEFAULT_FORT_DEFENSE, SECOND_PLAYER_FORT_ADVANTAGE};
use crate::interpreter::mocking::codex::CODEX_GD_NAME;
use crate::interpreter::error::EvalError;
use crate::interpreter::value::{SimpleValue, Value};
use code::serialize_game_code;

use thiserror::Error;
use rand_chacha::ChaCha8Rng;
use rand::{RngCore, SeedableRng};
use rand::seq::SliceRandom;
use strum_macros::Display;

use std::sync::Arc;

pub const LOOKAHEAD_AI_AGENT_PATH: &str = "res://card_game/playing_field/player_agent/lookahead_ai_agent/lookahead_ai_agent.gd";

// TODO Might make this a CLI arg, if we need it
pub const TURN_LIMIT: usize = 200;

/// Newtype wrapper around a superglobal state, indicating that it has
/// loaded the requisite files in order to play the card game. This
/// condition is unchecked.
///
/// `GameEngine` is cheap to clone, as it maintains an `Arc`
/// internally.
#[derive(Debug, Clone)]
pub struct GameEngine(pub Arc<SuperglobalState>);

/// The contents of the players' decks at the start of a card game.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CardGameEnv {
  pub bottom_deck: Deck,
  pub top_deck: Deck,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Display)]
#[strum(serialize_all = "UPPERCASE")]
pub enum GameWinner {
  Bottom,
  Top,
}

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum GameEngineError {
  #[error("{0}")]
  EvalError(#[from] EvalError),
  #[error("Deck of incorrect size was passed, decks must have size 20")]
  BadDeckSize,
  #[error("Got unknown result from card game: {0:?}")]
  UnknownResult(String),
}

impl GameEngine {
  pub fn new(state: SuperglobalState) -> Self {
    Self(Arc::new(state))
  }

  pub fn play_game_seeded(
    &self,
    env: &CardGameEnv,
    seed: u64,
  ) -> Result<GameWinner, GameEngineError> {
    let game_code = serialize_game_code(seed, env)?;
    tracing::info!("Running game with code: {game_code}");

    let random = ChaCha8Rng::seed_from_u64(seed);
    self.play_game(env, random)
  }

  pub fn play_game(
    &self,
    env: &CardGameEnv,
    random: impl RngCore + 'static,
  ) -> Result<GameWinner, GameEngineError> {
    if env.bottom_deck.len() != DECK_SIZE || env.top_deck.len() != DECK_SIZE {
      return Err(GameEngineError::BadDeckSize);
    }
    let (state, playing_field) = self.initialize_game(env, random)?;
    let Some(turn_transitions) = self.0.get_file(TURN_TRANSITIONS_RES_PATH) else {
      return Err(EvalError::UndefinedClass(String::from(TURN_TRANSITIONS_RES_PATH)).into());
    };
    state.call_function_on_class(&turn_transitions, "play_full_game", vec![playing_field.clone(), Value::from(TURN_LIMIT as i64)])?;
    let outcome = playing_field.get_value_raw(ENDGAME_VARIABLE, &self.0)?;
    let Value::String(outcome) = outcome else {
      return Err(GameEngineError::UnknownResult(format!("{outcome:?}")));
    };
    match &*outcome {
      "TOP" => Ok(GameWinner::Top),
      "BOTTOM" => Ok(GameWinner::Bottom),
      outcome => Err(GameEngineError::UnknownResult(format!("{outcome:?}"))),
    }
  }

  fn initialize_game(
    &self,
    env: &CardGameEnv,
    random: impl RngCore + 'static,
  ) -> Result<(EvaluatorState, Value), EvalError> {
    let state = EvaluatorState::new(Arc::clone(&self.0), random);
    let playing_field_class = state.superglobal_state().get_file(PLAYING_FIELD_RES_PATH)
      .ok_or_else(|| EvalError::UndefinedClass(String::from(PLAYING_FIELD_RES_PATH)))?;
    let playing_field = state.call_function_on_class(&playing_field_class, "new", Vec::new())?;
    {
      let bottom_deck = create_deck_of_cards(&state, env.bottom_deck.as_ref())?;
      install_deck(&state, &playing_field, "BOTTOM", bottom_deck)?;
    }
    {
      let top_deck = create_deck_of_cards(&state, env.top_deck.as_ref())?;
      install_deck(&state, &playing_field, "TOP", top_deck)?;
    }
    {
      let bottom_agent = create_ai_agent(&state)?;
      install_player_agent(&state, &playing_field, "BOTTOM", bottom_agent)?;
    }
    {
      let top_agent = create_ai_agent(&state)?;
      install_player_agent(&state, &playing_field, "TOP", top_agent)?;
    }
    {
      const SECOND_PLAYER_FORT_DEFENSE: Value = Value::Int(DEFAULT_FORT_DEFENSE + SECOND_PLAYER_FORT_ADVANTAGE);
      let top_stats = playing_field.get_value("__evilconsim_statspanel_top", state.superglobal_state())?;
      top_stats.set_value("max_fort_defense", SECOND_PLAYER_FORT_DEFENSE, state.superglobal_state())?;
      top_stats.set_value("fort_defense", SECOND_PLAYER_FORT_DEFENSE, state.superglobal_state())?;
    }
    Ok((state, playing_field))
  }
}

fn create_deck_of_cards(state: &EvaluatorState, cards: &[CardId]) -> Result<Value, EvalError> {
  assert!(cards.len() == DECK_SIZE, "Wrong deck size");
  let Some(SimpleValue::ClassRef(codex)) = state.superglobal_state().get_var(CODEX_GD_NAME) else {
    return Err(EvalError::UnknownClass(CODEX_GD_NAME.to_string()));
  };
  let mut cards = cards.iter()
    .map(|c| state.call_function_on_class(&codex, "get_entity", vec![Value::from(c.0)]))
    .collect::<Result<Vec<_>, _>>()?;
  state.do_random(|rng| cards.shuffle(rng));
  Ok(Value::new_array(cards))
}

fn install_deck(state: &EvaluatorState, playing_field: &Value, player: &str, deck: Value) -> Result<(), EvalError> {
  let relevant_deck = state.call_function_on(playing_field, "get_deck", vec![Value::from(player)])?;
  let card_container = state.call_function_on(&relevant_deck, "cards", Vec::new())?;
  state.call_function_on(&card_container, "replace_cards", vec![deck])?;
  Ok(())
}

fn create_ai_agent(state: &EvaluatorState) -> Result<Value, EvalError> {
  let Some(class) = state.superglobal_state().get_file(LOOKAHEAD_AI_AGENT_PATH) else {
    return Err(EvalError::UndefinedClass(LOOKAHEAD_AI_AGENT_PATH.to_string()));
  };
  state.call_function_on_class(&class, "new", Vec::new())
}

fn install_player_agent(state: &EvaluatorState, playing_field: &Value, player: &str, agent: Value) -> Result<(), EvalError> {
  // NOTE: Doesn't bother to call added_to_playing_field, since the
  // lookahead agent doesn't use it.
  let var_name = match player {
    "BOTTOM" => "_bottom_agent",
    "TOP" => "_top_agent",
    _ => { return Err(EvalError::domain_error("Expected TOP or BOTTOM")); }
  };
  agent.set_value("controlled_player", Value::from(player), state.superglobal_state())?;
  playing_field.set_value(var_name, agent, state.superglobal_state())?;
  Ok(())
}

impl From<code::SerializeError> for GameEngineError {
  fn from(e: code::SerializeError) -> Self {
    match e {
      code::SerializeError::BadDeckSize => GameEngineError::BadDeckSize,
    }
  }
}
