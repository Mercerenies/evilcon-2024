
//! Genetic algorithm for identifying good decks in the card game.

mod bradley_terry;

use crate::driver;
use crate::cardgame::{GameEngine, Deck, CardId, DECK_SIZE};
use crate::cardgame::deck::validator::DeckValidator;
use crate::interpreter::mocking::codex::CodexDataFile;

use rand::Rng;
use rand::rngs::ThreadRng;
use rand::seq::SliceRandom;
use threadpool::ThreadPool;

use std::sync::Arc;

pub const GENERATION_SIZE: usize = 3_000;
pub const TOTAL_MATCHUPS_PER_INDIVIDUAL: usize = 100;
pub const TOTAL_GAMES_PER_MATCHUP: usize = 120;

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
  left_index: usize,
  right_index: usize,
  left_wins: u64,
  right_wins: u64,
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
      let _span_guard = tracing::info_span!("generation", index = index).entered();
      tracing::info!("Running generation {} of {}", index, generation_count);
      self.run_one_generation(&generation_pool);
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

  fn run_one_generation(&mut self, generation: &Arc<Vec<Deck>>) {

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
  engine: Arc<GameEngine>,
  generation: Arc<Vec<Deck>>,
  left_index: usize,
  right_index: usize,
) {
  let left_deck = &generation[left_index];
  let right_deck = &generation[right_index];

  let mut results = MatchupsResult::default();
  for _ in 0..TOTAL_GAMES_PER_MATCHUP {
    
  }
}
