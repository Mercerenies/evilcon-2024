
use super::string::GdString;
use super::identifier::Identifier;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Expr {
  Array(Vec<Expr>),
  Literal(Literal),
  Name(Identifier),
  Call { func: Box<Expr>, args: Vec<Expr> },
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Literal {
  Bool(bool),
  Int(i64),
  String(GdString),
}

impl From<Literal> for Expr {
  fn from(l: Literal) -> Self {
    Expr::Literal(l)
  }
}

impl From<i64> for Literal {
  fn from(i: i64) -> Self {
    Literal::Int(i)
  }
}

impl From<bool> for Literal {
  fn from(b: bool) -> Self {
    Literal::Bool(b)
  }
}

impl From<i64> for Expr {
  fn from(i: i64) -> Self {
    Expr::Literal(Literal::Int(i))
  }
}

impl From<bool> for Expr {
  fn from(b: bool) -> Self {
    Expr::Literal(Literal::Bool(b))
  }
}
