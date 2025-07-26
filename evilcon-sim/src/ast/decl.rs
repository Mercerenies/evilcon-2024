
use super::identifier::Identifier;
use super::expr::Expr;
use super::stmt::{Stmt, VarStmt};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Decl {
  Const { name: Identifier, value: Box<Expr> },
  Var(VarStmt),
  Function(FunctionDecl),
  Constructor(ConstructorDecl),
  Enum(EnumDecl),
  /// Very limited support for nested classes: No access to outer
  /// scope, and nested classes ALWAYS inherit directly from
  /// RefCounted for now.
  InnerClass(Identifier, Vec<Decl>),
  /// Signals compile to instances of the `Signal` class, which is a
  /// minimal mocking class that contains no-op methods `emit` and
  /// `connect`.
  Signal(Identifier),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FunctionDecl {
  pub name: Identifier,
  pub params: Vec<Parameter>,
  pub is_static: bool,
  pub body: Vec<Stmt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ConstructorDecl {
  pub params: Vec<Parameter>,
  pub body: Vec<Stmt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct EnumDecl {
  pub name: Identifier,
  pub members: Vec<(Identifier, Option<Expr>)>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Parameter {
  pub name: String,
  pub default_value: Option<Expr>,
}
