
use super::string::GdString;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Expr {
  Literal(Literal),
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
