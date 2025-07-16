
use super::identifier::Identifier;
use super::expr::Expr;
use super::stmt::{Stmt, VarStmt};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Decl {
  Const { name: Identifier, value: Box<Expr> },
  Var(VarStmt),
  Function(FunctionDecl),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FunctionDecl {
  pub name: Identifier,
  pub params: Vec<Identifier>,
  pub is_static: bool,
  pub body: Vec<Stmt>,
}
