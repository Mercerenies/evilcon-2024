
pub mod validator;

pub use validator::DeckValidator;

use thiserror::Error;

use std::str::FromStr;
use std::num::ParseIntError;
use std::fmt::{self, Display, Formatter};

pub const DECK_SIZE: usize = 20;

/// Newtype wrapper around a vector of [`CardId`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Deck(pub Vec<CardId>);

/// The ID of a playing card.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CardId(pub i64);

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum DeckFromStrError {
  #[error("{0}")]
  ParseIntError(#[from] ParseIntError),
}

impl Deck {
  pub fn is_empty(&self) -> bool {
    self.0.is_empty()
  }

  pub fn len(&self) -> usize {
    self.0.len()
  }
}

impl AsRef<[CardId]> for Deck {
  fn as_ref(&self) -> &[CardId] {
    &self.0
  }
}

impl FromIterator<CardId> for Deck {
  fn from_iter<I: IntoIterator<Item = CardId>>(iter: I) -> Self {
    Self(iter.into_iter().collect())
  }
}

impl FromStr for Deck {
  type Err = DeckFromStrError;

  /// Parses comma-separated list of integers. Ignores whitespace
  /// around numbers.
  fn from_str(s: &str) -> Result<Self, DeckFromStrError> {
    let cards = s.split(',')
      .map(|s| s.trim())
      .filter(|s| !s.is_empty())
      .map(|s| s.parse::<i64>().map(CardId))
      .collect::<Result<Vec<_>, _>>()?;
    Ok(Deck(cards))
  }
}

impl Display for Deck {
  fn fmt(&self, f: &mut Formatter) -> fmt::Result {
    let mut first = true;
    for card in &self.0 {
      if !first {
        write!(f, ", ")?;
      }
      write!(f, "{}", card.0)?;
      first = false;
    }
    Ok(())
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_deck_from_str() {
    let deck: Deck = "1, 2, 3, 4, 5".parse().unwrap();
    assert_eq!(deck.0, vec![CardId(1), CardId(2), CardId(3), CardId(4), CardId(5)]);
  }

  #[test]
  fn test_deck_from_str_empty() {
    let deck: Deck = "".parse().unwrap();
    assert!(deck.is_empty(), "Deck {:?} is not empty", deck);
  }

  #[test]
  fn test_deck_from_str_invalid() {
    "a".parse::<Deck>().unwrap_err();
  }
}
