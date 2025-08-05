
//! Command line args.

use crate::cardgame::Deck;

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
  /// Plays a single instance of the card game from a hex code.
  PlayFromCode {
    /// The base64-encoded string containing the game's seed and
    /// player decks.
    code: String,
  },
  /// Plays the card game one or more times with the supplied player
  /// decks.
  PlaySequential {
    /// Random seed as a u64. If not provided, generator will be
    /// randomly seeded.
    #[arg(long)]
    seed: Option<u64>,
    /// Number of runs to perform.
    #[arg(short = 'n', long, default_value_t = 1)]
    count: u32,
    /// Bottom player's deck.
    #[arg(short, long = "bottom")]
    bottom_deck: Deck,
    /// Top player's deck.
    #[arg(short, long = "top")]
    top_deck: Deck,
  },
}
