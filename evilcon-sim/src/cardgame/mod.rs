
use crate::interpreter::eval::SuperglobalState;
use crate::interpreter::error::EvalError;

use thiserror::Error;

pub const DECK_SIZE: usize = 20;

/// Newtype wrapper around a superglobal state, indicating that it has
/// loaded the requisite files in order to play the card game. This
/// condition is unchecked.
#[derive(Debug, Clone)]
pub struct GameEngine(pub SuperglobalState);

/// The ID of a playing card.
#[derive(Debug, Clone, Copy)]
pub struct CardId(pub i64);

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum GameEngineError {
  #[error("{0}")]
  EvalError(#[from] EvalError),
  #[error("Deck of incorrect size was passed, decks must have size 20")]
  BadDeckSize,
}

impl GameEngine {
}
