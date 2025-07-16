
use std::borrow::Borrow;

/// Thin wrapper around a string, marking it as an identifier.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Identifier(pub String);

impl Identifier {
  pub fn new(s: impl Into<String>) -> Self {
    Self(s.into())
  }
}

impl From<String> for Identifier {
  fn from(s: String) -> Self {
    Self(s)
  }
}

impl<'a> From<&'a str> for Identifier {
  fn from(s: &'a str) -> Self {
    Self(s.to_owned())
  }
}

impl From<Identifier> for String {
  fn from(i: Identifier) -> Self {
    i.0
  }
}

impl AsRef<str> for Identifier {
  fn as_ref(&self) -> &str {
    &self.0
  }
}

impl Borrow<str> for Identifier {
  fn borrow(&self) -> &str {
    &self.0
  }
}
