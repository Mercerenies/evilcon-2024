
use super::identifier::Identifier;
use super::expr::Expr;
use super::stmt::Stmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Decl {
  Const { name: Identifier, value: Box<Expr> },
  Function(FunctionDecl),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FunctionDecl {
  pub name: Identifier,
  pub params: Vec<Identifier>,
  pub body: Vec<Stmt>,
}
