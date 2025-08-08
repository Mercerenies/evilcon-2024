
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
use threadpool::ThreadPool;

use std::sync::Arc;
use std::sync::mpsc::{self, Sender};
use std::thread;

pub const GENERATION_SIZE: usize = 3_000;
pub const TOTAL_MATCHUPS_PER_INDIVIDUAL: usize = 100;
pub const TOTAL_GAMES_PER_MATCHUP: usize = 130;

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

  pub fn run_genetic_algorithm(&mut self, generation_count: usize) {
    let mut generation_pool = Arc::new(self.generate_initial_generation_pool());
    for index in 1..=generation_count {
      let span = tracing::info_span!("generation", index = index);
      let _span_guard = span.enter();
      tracing::info!("Running generation {} of {}", index, generation_count);
      let scores = self.run_one_generation(&generation_pool, &span);
      dbg!(&scores);
      break;
    }
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
