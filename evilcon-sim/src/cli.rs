
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
  /// Validate a deck of cards, without playing a game.
  ValidateDeck {
    deck: Deck,
  },
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
  /// Plays the card game one or more times with the supplied player
  /// decks, using multiple threads to run in parallel.
  PlayParallel {
    /// Random seed as a u64. If not provided, generator will be
    /// randomly seeded.
    #[arg(long)]
    seed: Option<u64>,
    /// Number of runs to perform.
    #[arg(short = 'n', long, default_value_t = 1)]
    count: u32,
    /// Number of threads to utilize. If not supplied, a best estimate
    /// will be made based on the CPU capabilities of the host
    /// machine.
    #[arg(long = "threads")]
    thread_count: Option<usize>,
    /// Bottom player's deck.
    #[arg(short, long = "bottom")]
    bottom_deck: Deck,
    /// Top player's deck.
    #[arg(short, long = "top")]
    top_deck: Deck,
  },
  /// Runs a genetic algorithm to identify the most powerful decks.
  RunGeneticAlgorithm {
    /// Number of generations to run.
    #[arg(long)]
    generations: usize,
    /// Number of threads to utilize. If not supplied, a best estimate
    /// will be made based on the CPU capabilities of the host
    /// machine.
    #[arg(long = "threads")]
    thread_count: Option<usize>,
  }
}

impl Command {
  pub fn min_log_level(&self) -> &'static str {
    match self {
      Self::RunGeneticAlgorithm { .. } => "info",
      _ => "trace"
    }
  }
}
