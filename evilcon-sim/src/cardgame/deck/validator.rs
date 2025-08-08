
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
  MoreThanThreeCopies(CardType),
  DuplicateLimited(CardType),
  DuplicateUltraRare(CardType),
}

/// A card ID tagged with its name.
#[derive(Debug, Clone)]
pub struct CardType {
  pub id: CardId,
  pub name: String,
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
          errors.push(DeckValidityError::DuplicateLimited(codex_entry.clone().into()));
        } else {
          errors.push(DeckValidityError::MoreThanThreeCopies(codex_entry.clone().into()));
        }
      }
      // Additionally, as a separate check, look at Ultra Rares.
      if count > 1 && codex_entry.rarity == Rarity::UltraRare {
        errors.push(DeckValidityError::DuplicateUltraRare(codex_entry.clone().into()));
      }
    }
    errors
  }

  // TODO This method is here because validator is the only place we
  // build the codex into a hash map. In principle, this should be
  // somewhere in codex.
  pub fn pretty_to_string(&self, deck: &[CardId]) -> String {
    let mut output = String::new();
    let mut first = true;
    for card_id in deck {
      if first {
        first = false;
      } else {
        output.push_str(", ");
      }
      let card_name = self.codex_dict.get(card_id).map(|entry| &*entry.name).unwrap_or("???");
      output.push_str(&format!("{card_id} ({card_name})"));
    }
    output
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

impl Display for CardType {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    write!(f, "{} ({})", self.name, self.id)
  }
}

impl From<CodexEntry> for CardType {
  fn from(codex_entry: CodexEntry) -> CardType {
    CardType {
      id: CardId(codex_entry.id),
      name: codex_entry.name,
    }
  }
}
