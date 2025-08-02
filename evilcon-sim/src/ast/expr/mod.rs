
pub mod operator;

use super::string::GdString;
use super::stmt::Stmt;
use super::decl::Parameter;
use super::identifier::Identifier;
use operator::{UnaryOp, BinaryOp};

use ordered_float::OrderedFloat;

use std::sync::Arc;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Expr {
  Array(Vec<Expr>),
  Dictionary(Vec<DictEntry>),
  Literal(Literal),
  Name(Identifier),
  GetNode(Identifier),
  Call { func: Box<Expr>, args: Vec<Expr> },
  Subscript(Box<Expr>, Box<Expr>),
  Attr(Box<Expr>, Identifier),
  AttrCall(Box<Expr>, Identifier, Vec<Expr>),
  BinaryOp(Box<Expr>, BinaryOp, Box<Expr>),
  UnaryOp(UnaryOp, Box<Expr>),
  Await(Box<Expr>),
  /// `Arc` so we can easily clone it into runtime values.
  Lambda(Arc<Lambda>),
  Conditional {
    if_true: Box<Expr>,
    cond: Box<Expr>,
    if_false: Box<Expr>,
  },
  /// No expression in GDScript compiles to this, but signal
  /// declarations use this expression as the initializer.
  NewSignal,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct DictEntry {
  pub key: Expr,
  pub value: Expr,
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
  Null,
  Bool(bool),
  Int(i64),
  Float(OrderedFloat<f64>),
  String(GdString),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Lambda {
  pub name: Option<Identifier>,
  pub params: Vec<Parameter>,
  pub body: Vec<Stmt>,
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

  pub fn attr_call(self, name: impl Into<String>, args: Vec<Expr>) -> Expr {
    self.attr(AttrTarget::Call(Identifier::new(name), args))
  }

  pub fn name(s: impl Into<String>) -> Expr {
    Expr::Name(Identifier::new(s))
  }

  pub fn string(s: impl Into<String>) -> Expr {
    Expr::Literal(Literal::String(GdString::simple(s)))
  }

  pub fn call(name: impl Into<String>, args: Vec<Expr>) -> Expr {
    Expr::Call {
      func: Box::new(Self::name(name)),
      args,
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

impl From<f64> for Literal {
  fn from(f: f64) -> Self {
    Literal::Float(OrderedFloat(f))
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

impl From<f64> for Expr {
  fn from(f: f64) -> Self {
    Expr::Literal(Literal::Float(OrderedFloat(f)))
  }
}

impl From<bool> for Expr {
  fn from(b: bool) -> Self {
    Expr::Literal(Literal::Bool(b))
  }
}

impl From<String> for Expr {
  fn from(s: String) -> Self {
    Expr::Literal(Literal::String(GdString::simple(s)))
  }
}

impl From<&str> for Expr {
  fn from(s: &str) -> Self {
    Expr::Literal(Literal::String(GdString::simple(s.to_string())))
  }
}
