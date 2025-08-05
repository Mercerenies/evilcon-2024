
pub const DECK_SIZE: usize = 20;

/// Newtype wrapper around a vector of [`CardId`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Deck(pub Vec<CardId>);

/// The ID of a playing card.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CardId(pub i64);

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
