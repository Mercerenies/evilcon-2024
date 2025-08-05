
use evilcon_sim::cli::{self, CliArgs};
use evilcon_sim::{runner, logging};
use evilcon_sim::cardgame::CardGameEnv;

use clap::Parser;

fn main() -> anyhow::Result<()> {
  let _worker_guard = logging::init_logger();
  let args = CliArgs::parse();
  match args.command {
    cli::Command::PlayFromCode { code } => {
      runner::play_from_code(&code)?;
    }
    cli::Command::PlaySequential { seed, count, bottom_deck, top_deck } => {
      let env = CardGameEnv { bottom_deck, top_deck };
      runner::play_sequential(&env, seed, count)?;
    }
  }
  Ok(())
}
