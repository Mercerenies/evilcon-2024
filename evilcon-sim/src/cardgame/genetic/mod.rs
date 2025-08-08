
//! Genetic algorithm for identifying good decks in the card game.

mod bradley_terry;

use crate::driver;
use crate::cardgame::{GameEngine, CardGameEnv, GameWinner, Deck, CardId, DECK_SIZE};
use crate::cardgame::deck::validator::DeckValidator;
use crate::cardgame::code::serialize_game_code;
use crate::interpreter::mocking::codex::CodexDataFile;
use bradley_terry::{WinMatrix, compute_scores};

use rand::Rng;
use rand::rngs::ThreadRng;
use rand::seq::SliceRandom;
use rand::distr::Distribution;
use rand::distr::weighted::WeightedIndex;
use threadpool::ThreadPool;

use std::sync::Arc;
use std::sync::mpsc::{self, Sender};
use std::thread;

const GENERATION_SIZE: usize = 100;
const TOTAL_MATCHUPS_PER_INDIVIDUAL: usize = 15;
const TOTAL_GAMES_PER_MATCHUP: usize = 5;

pub const ELITE_DECKS: usize = 10;
const CANDIDATE_PARENT_DECKS: usize = 50;
const MUTATION_RATE: f64 = 0.02;

#[derive(Debug)]
pub struct GeneticAlgorithm<'a> {
  random: ThreadRng,
  codex: CodexDataFile,
  validator: DeckValidator,
  thread_pool: &'a ThreadPool,
  engine: Arc<GameEngine>,
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
  pub fn new(thread_pool: &'a ThreadPool) -> anyhow::Result<Self> {
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
    let mut generation_pool = Arc::new(self.generate_initial_generation_pool());
    for index in 1..=generation_count {
      let span = tracing::info_span!("generation", index = index);
      let _span_guard = span.enter();
      tracing::info!("Running generation {} of {}", index, generation_count);
      let scores = self.run_one_generation(&generation_pool, &span);
      let mut deck_indices_by_rank = (0..GENERATION_SIZE).collect::<Vec<_>>();
      deck_indices_by_rank.sort_by(|&a, &b| scores[b].partial_cmp(&scores[a]).unwrap());

      let mut new_generation_pool = Vec::with_capacity(generation_pool.len());
      // Copy the first few elite decks over verbatim
      for i in 0..ELITE_DECKS {
        new_generation_pool.push(generation_pool[deck_indices_by_rank[i]].clone());
      }

      // Build weights (lowest-scoring should be set to zero)
      let mut weights = normalize_scores_to_positive(&scores);
      for i in &deck_indices_by_rank[CANDIDATE_PARENT_DECKS..] {
        weights[*i] = 0.0;
      }

      // Generate the rest by splicing genes
      let weighted = WeightedIndex::new(weights).unwrap();
      while new_generation_pool.len() < GENERATION_SIZE {
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
        if self.random.random::<f64>() < MUTATION_RATE {
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
    let mut decks = Vec::with_capacity(GENERATION_SIZE);
    while decks.len() < GENERATION_SIZE {
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
      for _ in 0..TOTAL_MATCHUPS_PER_INDIVIDUAL {
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
        self.thread_pool.execute(move || {
          let _span_guard = enclosing_span.enter();
          let _span_guard = tracing::info_span!("thread", thread_id = ?thread::current().id()).entered();
          play_games(sender, engine, generation, bottom_index, top_index);
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

fn play_games(
  out_channel: Sender<MatchupsResult>,
  engine: Arc<GameEngine>,
  generation: Arc<Vec<Deck>>,
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
  for _ in 0..TOTAL_GAMES_PER_MATCHUP {
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
