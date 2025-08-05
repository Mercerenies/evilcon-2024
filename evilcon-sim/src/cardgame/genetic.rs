
//! Genetic algorithm for identifying good decks in the card game.

use crate::cardgame::{Deck, CardId, DECK_SIZE};
use crate::cardgame::deck::validator::DeckValidator;
use crate::interpreter::mocking::codex::CodexDataFile;

use rand::Rng;
use rand::rngs::ThreadRng;
use rand::seq::SliceRandom;

#[derive(Debug)]
pub struct GeneticAlgorithm {
  random: ThreadRng,
  codex: CodexDataFile,
  validator: DeckValidator,
}

impl GeneticAlgorithm {
  pub fn new() -> anyhow::Result<Self> {
    let codex = CodexDataFile::read_from_default_file()?;
    let validator = DeckValidator::new(codex.clone());
    Ok(GeneticAlgorithm {
      random: rand::rng(),
      codex,
      validator,
    })
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
