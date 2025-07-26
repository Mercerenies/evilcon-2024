
use super::expr::Literal;

/// Pattern for pattern matching against in a `match` statement.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Pattern {
  Underscore,
  Literal(Literal),
}

impl From<Literal> for Pattern {
  fn from(lit: Literal) -> Self {
    Pattern::Literal(lit)
  }
}
