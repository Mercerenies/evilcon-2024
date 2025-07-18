
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
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FunctionDecl {
  pub name: Identifier,
  pub params: Vec<Identifier>,
  pub is_static: bool,
  pub body: Vec<Stmt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ConstructorDecl {
  pub params: Vec<Identifier>,
  pub body: Vec<Stmt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct EnumDecl {
  pub name: Identifier,
  pub members: Vec<(Identifier, Option<Expr>)>,
}
