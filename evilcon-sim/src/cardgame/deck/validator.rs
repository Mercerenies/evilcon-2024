
use crate::interpreter::mocking::codex::{CodexDataFile, CodexEntry, CodexLoadError, Rarity};
use super::CardId;

use itertools::Itertools;

use std::collections::HashMap;
use std::fmt::{self, Formatter, Display};

#[derive(Debug, Clone)]
pub struct DeckValidator {
  codex_dict: HashMap<CardId, CodexEntry>,
}

#[derive(Debug, Clone)]
pub enum DeckValidityError {
  MoreThanThreeCopies(CardId),
  DuplicateLimited(CardId),
  DuplicateUltraRare(CardId),
}

impl DeckValidator {
  pub fn new(codex: CodexDataFile) -> DeckValidator {
    let codex_dict = codex.cards.into_iter()
      .map(|entry| (CardId(entry.id), entry))
      .collect();
    DeckValidator { codex_dict }
  }

  pub fn load_default() -> Result<Self, CodexLoadError> {
    let codex = CodexDataFile::read_from_default_file()?;
    Ok(DeckValidator::new(codex))
  }

  /// Validates the deck and returns a list of the problems found. If
  /// the vector is empty, then no problems were found.
  pub fn validate_deck(&self, deck: &[CardId]) -> Vec<DeckValidityError> {
    let mut errors = Vec::new();
    let frequencies = deck.iter().copied().counts();
    for (card_id, count) in frequencies {
	    let codex_entry = self.codex_dict.get(&card_id);
      let Some(codex_entry) = codex_entry else {
        tracing::warn!("Could not find card with ID {card_id} in codex.");
        continue;
      };
      let hard_limit = if codex_entry.limited { 1 } else { 3 };
      if count > hard_limit {
        if codex_entry.limited {
          errors.push(DeckValidityError::DuplicateLimited(card_id));
        } else {
          errors.push(DeckValidityError::MoreThanThreeCopies(card_id));
        }
      }
      // Additionally, as a separate check, look at Ultra Rares.
      if count > 1 && codex_entry.rarity == Rarity::UltraRare {
        errors.push(DeckValidityError::DuplicateUltraRare(card_id));
      }
    }
    errors
  }
}

impl DeckValidityError {
  /// Having a duplicate ultra rare card is not strictly against the
  /// rules of the game, but it violates the design principles I'm
  /// writing most of these decks with. Thus, having a duplicate ultra
  /// rare card is a non-critical error.
  pub fn is_critical(&self) -> bool {
    !matches!(self, DeckValidityError::DuplicateUltraRare(_))
  }
}

impl Display for DeckValidityError {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    match self {
      DeckValidityError::MoreThanThreeCopies(card_id) => {
        write!(f, "Card {card_id} has more than three copies in the deck.")
      }
      DeckValidityError::DuplicateLimited(card_id) => {
        write!(f, "Card {card_id} is limited and has more than one copy in the deck.")
      }
      DeckValidityError::DuplicateUltraRare(card_id) => {
        write!(f, "Card {card_id} is ultra rare and has more than one copy in the deck.")
      }
    }
  }
}
