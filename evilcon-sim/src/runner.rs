
//! Top-level runner. `main` dispatches to one of these functions
//! directly.

use crate::driver;
use crate::cardgame::{GameEngine, CardGameEnv, GameWinner, CardId};
use crate::cardgame::deck::{DeckValidator, Deck};
use crate::cardgame::code::deserialize_game_code;

use std::process::ExitCode;
use std::sync::LazyLock;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum ValidationResult {
  Ok,
  Warn,
  CriticalError,
}

impl ValidationResult {
  pub fn to_status_code(self) -> u8 {
    match self {
      ValidationResult::Ok => 0,
      ValidationResult::Warn => 1,
      ValidationResult::CriticalError => 2,
    }
  }

  pub fn to_exit_code(self) -> ExitCode {
    ExitCode::from(self.to_status_code())
  }
}

pub fn validate_user_deck(deck: &Deck) -> ValidationResult {
  let res = validate_deck("USER", deck.as_ref());
  if res == ValidationResult::Ok {
    tracing::info!("Deck USER is valid.");
  }
  res
}

pub fn play_from_code(code_str: &str) -> anyhow::Result<()> {
  let (seed, env) = deserialize_game_code(code_str)?;
  tracing::info!("Running with user-provided seed: {seed}");
  tracing::info!("Player BOTTOM deck = {}", env.bottom_deck);
  tracing::info!("Player TOP deck = {}", env.top_deck);

  validate_deck("BOTTOM", env.bottom_deck.as_ref());
  validate_deck("TOP", env.top_deck.as_ref());

  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);
  let outcome = engine.play_game_seeded(&env, seed)?;
  tracing::info!("Game Winner: {}", outcome);
  Ok(())
}

pub fn play_sequential(env: &CardGameEnv, user_seed: Option<u64>, run_count: u32) -> anyhow::Result<()> {
  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);

  validate_deck("BOTTOM", env.bottom_deck.as_ref());
  validate_deck("TOP", env.top_deck.as_ref());

  let mut bottom_wins = 0;
  let mut top_wins = 0;
  for i in 0..run_count {
    tracing::info!("Run {} of {}", i + 1, run_count);
    let seed;
    if let Some(user_seed) = user_seed {
      seed = user_seed;
      tracing::info!("Running with user-provided seed: {seed}");
    } else {
      seed = rand::random::<u64>();
      tracing::info!("Running with random seed: {seed}");
    };
    tracing::info!("Player BOTTOM deck = {}", env.bottom_deck);
    tracing::info!("Player TOP deck = {}", env.top_deck);
    let outcome = engine.play_game_seeded(&env, seed)?;
    tracing::info!("Game Winner: {}", outcome);
    match outcome {
      GameWinner::Bottom => bottom_wins += 1,
      GameWinner::Top => top_wins += 1,
    }
  }
  tracing::info!("Player BOTTOM won {bottom_wins} time(s) of {run_count}");
  tracing::info!("Player TOP won {top_wins} time(s) of {run_count}");
  Ok(())
}

fn validate_deck(deck_name: &str, deck: &[CardId]) -> ValidationResult {
  static VALIDATOR: LazyLock<DeckValidator> = LazyLock::new(|| {
    DeckValidator::load_default()
      .expect("Could not load deck validator from codex YAML file")
  });
  let results = VALIDATOR.validate_deck(deck);
  let validation_result;
  if results.iter().any(|err| err.is_critical()) {
    tracing::error!("Deck {deck_name} is not legal!");
    validation_result = ValidationResult::CriticalError;
  } else if !results.is_empty() {
    tracing::warn!("Deck {deck_name} contains questionable design!");
    validation_result = ValidationResult::Warn;
  } else {
    validation_result = ValidationResult::Ok;
  }
  for err in results {
    if err.is_critical() {
      tracing::error!("{err}");
    } else {
      tracing::warn!("{err}");
    }
  }
  validation_result
}
