
use std::borrow::Borrow;
use std::fmt::{Display, Formatter};

/// Thin wrapper around a string, marking it as an identifier.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Identifier(pub String);

/// Thin wrapper around a string marking it as a pathname. Enforces no
/// invariants, but typically these strings should start with
/// "res://".
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ResourcePath(pub String);

impl Identifier {
  pub fn new(s: impl Into<String>) -> Self {
    Self(s.into())
  }
}

impl ResourcePath {
  pub fn new(s: impl Into<String>) -> Self {
    Self(s.into())
  }
}

impl From<String> for Identifier {
  fn from(s: String) -> Self {
    Self(s)
  }
}

impl From<String> for ResourcePath {
  fn from(s: String) -> Self {
    Self(s)
  }
}

impl<'a> From<&'a str> for Identifier {
  fn from(s: &'a str) -> Self {
    Self(s.to_owned())
  }
}

impl<'a> From<&'a str> for ResourcePath {
  fn from(s: &'a str) -> Self {
    Self(s.to_owned())
  }
}

impl From<Identifier> for String {
  fn from(i: Identifier) -> Self {
    i.0
  }
}

impl From<ResourcePath> for String {
  fn from(i: ResourcePath) -> Self {
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

impl AsRef<str> for ResourcePath {
  fn as_ref(&self) -> &str {
    &self.0
  }
}

impl Borrow<str> for ResourcePath {
  fn borrow(&self) -> &str {
    &self.0
  }
}

impl Display for Identifier {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    Display::fmt(&self.0, f)
  }
}

impl Display for ResourcePath {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    Display::fmt(&self.0, f)
  }
}
