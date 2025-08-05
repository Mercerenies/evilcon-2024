
//! Top-level runner. `main` dispatches to one of these functions
//! directly.

use crate::driver;
use crate::cardgame::{GameEngine, Deck};
use crate::cardgame::code::deserialize_game_code;

use itertools::Itertools;

pub fn play_from_code(code_str: &str) -> anyhow::Result<()> {
  let (seed, env) = deserialize_game_code(code_str)?;
  tracing::info!("Running with user-provided seed: {seed}");
  tracing::info!("Player BOTTOM deck = {}", show_deck(&env.bottom_deck));
  tracing::info!("Player TOP deck = {}", show_deck(&env.top_deck));

  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);
  let outcome = engine.play_game_seeded(&env, seed)?;
  tracing::info!("Game Winner: {}", outcome);
  Ok(())
}

fn show_deck(deck: &Deck) -> String {
  deck.as_ref()
    .iter()
    .map(|x| format!("{}", x.0))
    .join(", ")
}
