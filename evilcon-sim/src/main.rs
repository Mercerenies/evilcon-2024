
use evilcon_sim::driver;
use evilcon_sim::cli::{self, CliArgs};
use evilcon_sim::logging;
use evilcon_sim::cardgame::{GameEngine, CardId};
use evilcon_sim::cardgame::code::deserialize_game_code;

use clap::Parser;
use itertools::Itertools;

fn main() -> anyhow::Result<()> {
  let _worker_guard = logging::init_logger();
  let args = CliArgs::parse();
  match args.command {
    cli::Command::PlayFromCode { code } => {
      play_from_code(&code)?;
    }
  }
  Ok(())
}

fn play_from_code(code_str: &str) -> anyhow::Result<()> {
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

fn show_deck(deck: &[CardId]) -> String {
  deck.iter()
    .map(|x| format!("{}", x.0))
    .join(", ")
}
