
//! Command line args.

use clap::{Parser, Subcommand};

/// Evilcon card game simulation engine.
#[derive(Debug, Parser)]
#[command(author, version)]
pub struct CliArgs {
  #[command(subcommand)]
  pub command: Command,
}

#[derive(Debug, Subcommand)]
pub enum Command {
  /// Plays a single instance of the card game.
  PlayFromCode {
    /// The base64-encoded string containing the game's seed and
    /// player decks.
    code: String,
  }
}
