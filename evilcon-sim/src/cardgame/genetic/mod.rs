
//! Genetic algorithm for identifying good decks in the card game.

mod bradley_terry;

use crate::driver;
use crate::cardgame::{GameEngine, CardGameEnv, GameWinner, Deck, CardId, DECK_SIZE};
use crate::cardgame::deck::validator::DeckValidator;
use crate::cardgame::code::serialize_game_code;
use crate::interpreter::mocking::codex::CodexDataFile;
use bradley_terry::{WinMatrix, compute_scores};

use clap::Args;
use rand::Rng;
use rand::rngs::ThreadRng;
use rand::seq::SliceRandom;
use rand::distr::Distribution;
use rand::distr::weighted::WeightedIndex;
use threadpool::ThreadPool;

use std::sync::Arc;
use std::sync::mpsc::{self, Sender};
use std::thread;

#[derive(Debug)]
pub struct GeneticAlgorithm<'a> {
  random: ThreadRng,
  codex: CodexDataFile,
  validator: DeckValidator,
  thread_pool: &'a ThreadPool,
  engine: Arc<GameEngine>,
  args: GeneticAlgorithmArgs,
}

#[derive(Debug, Clone, Args)]
pub struct GeneticAlgorithmArgs {
  /// Number of individuals in each generation. (Default = 125)
  #[arg(long, default_value_t = 125)]
  pub generation_size: usize,
  /// Number of matchups per individual in each generation. (Default =
  /// 15)
  #[arg(long = "matchups-per-individual", default_value_t = 15)]
  pub total_matchups_per_individual: usize,
  /// Total number of games to play between two paired decks. (Default
  /// = 5)
  #[arg(long = "games-per-matchup", default_value_t = 5)]
  pub total_games_per_matchup: usize,
  /// The number of "elite" high-quality decks to carry over each
  /// generation verbatim. (default = 1/10 of generation size)
  #[arg(long = "elite-decks")]
  pub elite_deck_count: Option<usize>,
  /// The number of candidate parent decks to draw genetic material
  /// from at each generation. (default = 1/2 of generation size)
  #[arg(long = "candidate-parent-decks")]
  pub candidate_parent_deck_count: Option<usize>,
  /// Mutation rate, as a fraction from 0 to 1. (default = 0.03)
  #[arg(long, default_value_t = 0.03)]
  pub mutation_rate: f64,
}

#[derive(Debug, Clone, Default)]
struct MatchupsResult {
  bottom_index: usize,
  top_index: usize,
  bottom_wins: u64,
  top_wins: u64,
  error_outcomes: u64,
}

impl<'a> GeneticAlgorithm<'a> {
  pub fn new(
    thread_pool: &'a ThreadPool,
    args: GeneticAlgorithmArgs,
  ) -> anyhow::Result<Self> {
    let codex = CodexDataFile::read_from_default_file()?;
    let validator = DeckValidator::new(codex.clone());
    let superglobals = driver::load_all_files()?;
    let engine = Arc::new(GameEngine::new(superglobals));
    Ok(GeneticAlgorithm {
      random: rand::rng(),
      codex,
      validator,
      thread_pool,
      engine,
      args,
    })
  }

  pub fn validator(&self) -> &DeckValidator {
    &self.validator
  }

  pub fn codex(&self) -> &CodexDataFile {
    &self.codex
  }

  /// Runs the genetic algorithm with the given parameters. Returned
  /// decks include the "top" elite decks at the beginning, followed
  /// by final generation splices.
  pub fn run_genetic_algorithm(&mut self, generation_count: usize) -> Vec<Deck> {
    // Resolve default values for fields
    let generation_size = self.args.generation_size;
    let elite_deck_count = self.args.elite_deck_count();
    let candidate_parent_deck_count = self.args.candidate_parent_deck_count.unwrap_or(generation_size / 2);

    tracing::info!("Genetic Algorithm initiated");
    tracing::info!("Running {} generations of {} individuals each", generation_count, generation_size);
    tracing::info!("Additional parameters: total_matchups_per_individual = {}, total_games_per_matchup = {}, elite_deck_count = {}, candidate_parent_deck_count = {}, mutation_rate = {}",
                   self.args.total_matchups_per_individual,
                   self.args.total_games_per_matchup,
                   elite_deck_count,
                   candidate_parent_deck_count,
                   self.args.mutation_rate);

    let mut generation_pool = Arc::new(self.generate_initial_generation_pool());
    for index in 1..=generation_count {
      let span = tracing::info_span!("generation", index = index);
      let _span_guard = span.enter();
      tracing::info!("Running generation {} of {}", index, generation_count);
      let scores = self.run_one_generation(&generation_pool, &span);
      let mut deck_indices_by_rank = (0..generation_size).collect::<Vec<_>>();
      deck_indices_by_rank.sort_by(|&a, &b| scores[b].partial_cmp(&scores[a]).unwrap());

      let mut new_generation_pool = Vec::with_capacity(generation_pool.len());
      // Copy the first few elite decks over verbatim
      for i in 0..elite_deck_count {
        new_generation_pool.push(generation_pool[deck_indices_by_rank[i]].clone());
      }

      // Build weights (lowest-scoring should be set to zero)
      let mut weights = normalize_scores_to_positive(&scores);
      for i in &deck_indices_by_rank[candidate_parent_deck_count..] {
        weights[*i] = 0.0;
      }

      // Generate the rest by splicing genes
      let weighted = WeightedIndex::new(weights).unwrap();
      while new_generation_pool.len() < generation_size {
        let i = weighted.sample(&mut self.random);
        let j = weighted.sample(&mut self.random);
        if i == j {
          continue;
        }
        let deck_i = generation_pool[deck_indices_by_rank[i]].as_ref();
        let deck_j = generation_pool[deck_indices_by_rank[j]].as_ref();
        let new_deck = self.splice(deck_i, deck_j);
        if self.is_reasonable_deck(new_deck.as_ref()) {
          new_generation_pool.push(new_deck);
        }
      }

      // Mutate some of the individuals.
      for deck in &mut new_generation_pool {
        if self.random.random::<f64>() < self.args.mutation_rate {
          self.mutate(deck);
        }
      }

      // Final check; if any of the decks are invalid, replace them
      // with a new splice.
      for deck in &mut new_generation_pool {
        while !self.is_reasonable_deck(deck.as_ref()) {
          let i = weighted.sample(&mut self.random);
          let j = weighted.sample(&mut self.random);
          if i == j {
            continue;
          }
          *deck = self.splice(generation_pool[deck_indices_by_rank[i]].as_ref(), generation_pool[deck_indices_by_rank[j]].as_ref());
        }
      }

      generation_pool = Arc::new(new_generation_pool);
    }
    Arc::unwrap_or_clone(generation_pool)
  }

  fn generate_initial_generation_pool(&mut self) -> Vec<Deck> {
    let mut decks = Vec::with_capacity(self.args.generation_size);
    while decks.len() < self.args.generation_size {
      let deck = self.generate_random_deck();
      if self.is_reasonable_deck(deck.as_ref()) {
        decks.push(deck);
      }
    }
    decks
  }

  /// Generates a completely random deck. Note that this deck MIGHT
  /// NOT be valid.
  fn generate_random_deck(&mut self) -> Deck {
    let mut new_deck = Vec::with_capacity(DECK_SIZE);
    for _ in 0..DECK_SIZE {
      let new_card_id = self.random.random_range(1..=self.codex.max_id);
      new_deck.push(CardId(new_card_id));
    }
    Deck(new_deck)
  }

  fn run_one_generation(&mut self, generation: &Arc<Vec<Deck>>, span: &tracing::Span) -> Vec<f64> {
    let (sender, receiver) = mpsc::channel();
    let mut total_matches = 0;
    for bottom_index in 0..generation.len() {
      for _ in 0..self.args.total_matchups_per_individual {
        let top_index = self.random.random_range(0..generation.len());
        if top_index == bottom_index {
          // Don't do self-matchups; it'll confuse the logistic
          // regression.
          continue
        }
        total_matches += 1;
        let sender = sender.clone();
        let engine = Arc::clone(&self.engine);
        let generation = Arc::clone(&generation);
        let enclosing_span = span.clone();
        let total_matchups_per_individual = self.args.total_matchups_per_individual;
        self.thread_pool.execute(move || {
          let _span_guard = enclosing_span.enter();
          let _span_guard = tracing::info_span!("thread", thread_id = ?thread::current().id()).entered();
          play_games(sender, engine, generation, total_matchups_per_individual, bottom_index, top_index);
        });
      }
    }

    // Collect results
    let mut win_matrix = WinMatrix::zeroes(generation.len());
    for _ in 0..total_matches {
      let outcome = receiver.recv().unwrap();
      win_matrix[(outcome.bottom_index, outcome.top_index)] += outcome.bottom_wins;
      win_matrix[(outcome.top_index, outcome.bottom_index)] += outcome.top_wins;
    }

    // Logistic regression
    compute_scores(&win_matrix)
  }

  fn splice(&mut self, deck1: &[CardId], deck2: &[CardId]) -> Deck {
    let mut new_deck = Vec::with_capacity(DECK_SIZE);
    for i in 0..DECK_SIZE {
      let deck_to_pull_from = if self.random.random() { deck1 } else { deck2 };
      new_deck.push(deck_to_pull_from[i]);
    }
    new_deck.shuffle(&mut self.random);
    Deck(new_deck)
  }

  fn mutate(&mut self, deck: &mut Deck) {
    let index = self.random.random_range(0..DECK_SIZE);
    let new_card_id = self.random.random_range(1..=self.codex.max_id);
    deck[index] = CardId(new_card_id);
  }

  pub fn is_reasonable_deck(&self, deck: &[CardId]) -> bool {
    let errors = self.validator.validate_deck(deck);
    errors.is_empty()
  }
}

impl GeneticAlgorithmArgs {
  pub fn elite_deck_count(&self) -> usize {
    self.elite_deck_count.unwrap_or(self.generation_size / 10)
  }
}

fn play_games(
  out_channel: Sender<MatchupsResult>,
  engine: Arc<GameEngine>,
  generation: Arc<Vec<Deck>>,
  games_count: usize,
  bottom_index: usize,
  top_index: usize,
) {
  let env = CardGameEnv {
    bottom_deck: &generation[bottom_index],
    top_deck: &generation[top_index],
  };

  let mut results = MatchupsResult::default();
  results.bottom_index = bottom_index;
  results.top_index = top_index;
  for _ in 0..games_count {
    let seed = rand::rng().random::<u64>();
    match engine.play_game_seeded(&env, seed) {
      Ok(GameWinner::Top) => {
        results.top_wins += 1;
      }
      Ok(GameWinner::Bottom) => {
        results.bottom_wins += 1;
      }
      Err(err) => {
        results.error_outcomes += 1;
        let game_code = serialize_game_code(seed, &env).unwrap_or_else(|_| "(failed to get game code)".to_owned());
        tracing::error!(%game_code, "Error during game: {}", err.root_cause());
      }
    }
  }
  out_channel.send(results).unwrap();
}

/// Add a constant to all scores to force them all to be greater than
/// zero.
fn normalize_scores_to_positive(scores: &[f64]) -> Vec<f64> {
  const EPSILON: f64 = 0.01;

  let min = scores.iter().copied().min_by(|a, b| a.partial_cmp(b).unwrap()).unwrap();
  scores.iter().map(|s| s - min + EPSILON).collect()
}
