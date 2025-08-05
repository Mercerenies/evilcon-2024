
//! Top-level runner. `main` dispatches to one of these functions
//! directly.

use crate::driver;
use crate::cardgame::{GameEngine, CardGameEnv, GameWinner};
use crate::cardgame::code::deserialize_game_code;

pub fn play_from_code(code_str: &str) -> anyhow::Result<()> {
  let (seed, env) = deserialize_game_code(code_str)?;
  tracing::info!("Running with user-provided seed: {seed}");
  tracing::info!("Player BOTTOM deck = {}", env.bottom_deck);
  tracing::info!("Player TOP deck = {}", env.top_deck);

  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);
  let outcome = engine.play_game_seeded(&env, seed)?;
  tracing::info!("Game Winner: {}", outcome);
  Ok(())
}

pub fn play_sequential(env: &CardGameEnv, user_seed: Option<u64>, run_count: u32) -> anyhow::Result<()> {
  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);

  let mut bottom_wins = 0;
  let mut top_wins = 0;
  for i in 0..run_count {
    tracing::info!("Run {i} of {run_count}");
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
