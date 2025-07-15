
use super::string::GdString;
use super::identifier::Identifier;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Expr {
  Array(Vec<Expr>),
  Literal(Literal),
  Name(Identifier),
  Call { func: Box<Expr>, args: Vec<Expr> },
  Subscript(Box<Expr>, Box<Expr>),
  Attr(Box<Expr>, Identifier),
  AttrCall(Box<Expr>, Identifier, Vec<Expr>),
}

/// Intermediate type used in compiling attribute expressions.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum AttrTarget {
  Name(Identifier),
  Subscript(Identifier, Box<Expr>),
  Call(Identifier, Vec<Expr>),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Literal {
  Bool(bool),
  Int(i64),
  String(GdString),
}

impl Expr {
  pub fn attr(self, target: AttrTarget) -> Expr {
    match target {
      AttrTarget::Name(id) => Expr::Attr(Box::new(self), id),
      AttrTarget::Call(id, args) => Expr::AttrCall(Box::new(self), id, args),
      AttrTarget::Subscript(id, key) => {
        // No idea why the tree_sitter parser treats this one
        // specially, as GDScript semantics always treat it as an attr
        // followed by a subscript.
        Expr::Subscript(Box::new(Expr::Attr(Box::new(self), id)), key)
      }
    }
  }
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
