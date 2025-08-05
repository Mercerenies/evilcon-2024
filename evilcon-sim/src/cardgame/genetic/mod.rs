
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

#[derive(Debug)]
pub struct GeneticAlgorithm<'a> {
  random: ThreadRng,
  codex: CodexDataFile,
  validator: DeckValidator,
  thread_pool: &'a ThreadPool,
  engine: Arc<GameEngine>,
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

  /// Generates a completely random deck. Note that this deck MIGHT
  /// NOT be valid.
  pub fn generate_random_deck(&mut self) -> Deck {
    let mut new_deck = Vec::with_capacity(DECK_SIZE);
    for _ in 0..DECK_SIZE {
      let new_card_id = self.random.random_range(1..=self.codex.max_id);
      new_deck.push(CardId(new_card_id));
    }
    Deck(new_deck)
  }

  pub fn splice(&mut self, deck1: &[CardId], deck2: &[CardId]) -> Deck {
    let mut new_deck = Vec::with_capacity(DECK_SIZE);
    for i in 0..DECK_SIZE {
      let deck_to_pull_from = if self.random.random() { deck1 } else { deck2 };
      new_deck.push(deck_to_pull_from[i]);
    }
    new_deck.shuffle(&mut self.random);
    Deck(new_deck)
  }

  pub fn mutate(&mut self, deck: &mut Deck) {
    let index = self.random.random_range(0..DECK_SIZE);
    let new_card_id = self.random.random_range(1..=self.codex.max_id);
    deck[index] = CardId(new_card_id);
  }

  pub fn is_reasonable_deck(&self, deck: &[CardId]) -> bool {
    let errors = self.validator.validate_deck(deck);
    errors.is_empty()
  }
}
