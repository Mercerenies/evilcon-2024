
use super::string::GdString;
use super::identifier::Identifier;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Expr {
  Literal(Literal),
  Name(Identifier),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Literal {
  String(GdString),
}

impl From<Literal> for Expr {
  fn from(l: Literal) -> Self {
    Expr::Literal(l)
  }
}
