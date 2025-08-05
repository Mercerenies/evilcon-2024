
use evilcon_sim::cli::{self, CliArgs};
use evilcon_sim::{runner, logging};
use evilcon_sim::cardgame::CardGameEnv;

use clap::Parser;

use std::process::ExitCode;

fn main() -> anyhow::Result<ExitCode> {
  let _worker_guard = logging::init_logger();
  let args = CliArgs::parse();
  match args.command {
    cli::Command::ValidateDeck { deck } => {
      let res = runner::validate_user_deck(&deck);
      Ok(res.to_exit_code())
    }
    cli::Command::PlayFromCode { code } => {
      runner::play_from_code(&code)?;
      Ok(ExitCode::SUCCESS)
    }
    cli::Command::PlaySequential { seed, count, bottom_deck, top_deck } => {
      let env = CardGameEnv { bottom_deck, top_deck };
      runner::play_sequential(&env, seed, count)?;
      Ok(ExitCode::SUCCESS)
    }
  }
}
