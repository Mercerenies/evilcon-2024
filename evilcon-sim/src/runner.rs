
//! Top-level runner. `main` dispatches to one of these functions
//! directly.

use crate::driver;
use crate::cardgame::{GameEngine, GameEngineError, CardGameEnv, GameWinner, CardId};
use crate::cardgame::deck::{DeckValidator, Deck};
use crate::cardgame::code::deserialize_game_code;
use crate::cardgame::genetic::GeneticAlgorithm;

use threadpool::ThreadPool;

use std::process::ExitCode;
use std::sync::{Arc, LazyLock};
use std::sync::mpsc;
use std::thread;

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

  tracing::info!("Running sequentially {} game(s)", run_count);

  let mut bottom_wins = 0;
  let mut top_wins = 0;
  for i in 0..run_count {
    let _span_guard = tracing::info_span!("run", index = i + 1).entered();
    tracing::info!("Run {} of {}", i + 1, run_count);
    let seed = resolve_seed(user_seed);
    tracing::debug!("Player BOTTOM deck = {}", env.bottom_deck);
    tracing::debug!("Player TOP deck = {}", env.top_deck);
    let outcome = engine.play_game_seeded(&env, seed)?;
    tracing::info!("Game {} Winner: {}", i + 1, outcome);
    match outcome {
      GameWinner::Bottom => bottom_wins += 1,
      GameWinner::Top => top_wins += 1,
    }
  }
  tracing::info!("Player BOTTOM won {bottom_wins} time(s) of {run_count}");
  tracing::info!("Player TOP won {top_wins} time(s) of {run_count}");
  Ok(())
}

pub fn play_parallel(env: CardGameEnv, user_seed: Option<u64>, run_count: u32, thread_count: Option<usize>) -> anyhow::Result<()> {
  let env = Arc::new(env);

  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);

  validate_deck("BOTTOM", env.bottom_deck.as_ref());
  validate_deck("TOP", env.top_deck.as_ref());

  let thread_count = thread_count.unwrap_or_else(get_cpu_cores);
  tracing::info!("Running {run_count} game(s) on {thread_count} thread(s)");
  let pool = ThreadPool::new(thread_count);

  let (tx, rx) = mpsc::channel::<(u32, Result<GameWinner, GameEngineError>)>();
  for i in 0..run_count {
    let tx = tx.clone();
    let seed = resolve_seed(user_seed);
    let env = Arc::clone(&env);
    let engine = engine.clone();
    pool.execute(move || {
      let _span_guard = tracing::info_span!("run", index = i + 1).entered();
      tracing::info!("Run {} of {}", i + 1, run_count);
      tracing::debug!("Player BOTTOM deck = {}", env.bottom_deck);
      tracing::debug!("Player TOP deck = {}", env.top_deck);
      let outcome_or_err = engine.play_game_seeded(&env, seed);
      match &outcome_or_err {
        Ok(outcome) => {
          tracing::info!("Game {} Winner: {}", i + 1, outcome);
        }
        Err(err) => {
          tracing::error!("Game {i} Error: {err}");
        }
      }
      if let Err(err) = tx.send((i, outcome_or_err)) {
        tracing::error!("Channel error in game thread: {err}");
      }
    });
  }

  // Collect results
  let mut bottom_wins = 0;
  let mut top_wins = 0;
  let mut error_outcomes = 0;
  for (_i, result) in rx.iter().take(run_count as usize) {
    match result {
      Ok(GameWinner::Bottom) => bottom_wins += 1,
      Ok(GameWinner::Top) => top_wins += 1,
      Err(_) => error_outcomes += 1,
    }
  }

  tracing::info!("Player BOTTOM won {bottom_wins} time(s) of {run_count}");
  tracing::info!("Player TOP won {top_wins} time(s) of {run_count}");
  tracing::info!("Game errored on {error_outcomes} time(s) of {run_count}");
  Ok(())
}

pub fn run_genetic_algorithm(thread_count: Option<usize>, generations: usize) -> anyhow::Result<()> {
  let thread_size = thread_count.unwrap_or_else(get_cpu_cores);
  let thread_pool = ThreadPool::new(thread_size);
  let mut genetic_algorithm = GeneticAlgorithm::new(&thread_pool)?;
  genetic_algorithm.run_genetic_algorithm(generations);
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

fn get_cpu_cores() -> usize {
  match thread::available_parallelism() {
    Ok(count) => count.into(),
    Err(err) => {
      tracing::error!("Could not get available parallelism: {err}");
      4
    }
  }
}

/// If user seed was provided, return it. If not, generate one with
/// system-provided entropy.
fn resolve_seed(user_seed: Option<u64>) -> u64 {
  let seed;
  if let Some(user_seed) = user_seed {
    seed = user_seed;
    tracing::info!("Running with user-provided seed: {seed}");
  } else {
    seed = rand::random::<u64>();
    tracing::info!("Running with random seed: {seed}");
  };
  seed
}
