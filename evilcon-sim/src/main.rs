
use evilcon_sim::cli::{self, CliArgs};
use evilcon_sim::{runner, logging};

use clap::Parser;

fn main() -> anyhow::Result<()> {
  let _worker_guard = logging::init_logger();
  let args = CliArgs::parse();
  match args.command {
    cli::Command::PlayFromCode { code } => {
      runner::play_from_code(&code)?;
    }
  }
  Ok(())
}
