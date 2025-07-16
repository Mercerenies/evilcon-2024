
/// Thin wrapper around a string, marking it as an identifier.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Identifier(pub String);

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
