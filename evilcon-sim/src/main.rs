
use evilcon_sim::cli::{self, CliArgs};
use evilcon_sim::{runner, logging};
use evilcon_sim::cardgame::CardGameEnv;

use clap::Parser;

use std::process::ExitCode;

fn main() -> anyhow::Result<ExitCode> {
  let args = CliArgs::parse();
  let _worker_guard = logging::init_logger(args.command.min_log_level());
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
    cli::Command::PlayParallel { seed, count, thread_count, bottom_deck, top_deck } => {
      let env = CardGameEnv { bottom_deck, top_deck };
      runner::play_parallel(env, seed, count, thread_count)?;
      Ok(ExitCode::SUCCESS)
    }
    cli::Command::RunGeneticAlgorithm { thread_count, generations } => {
      runner::run_genetic_algorithm(thread_count, generations)?;
      Ok(ExitCode::SUCCESS)
    }
  }
}
