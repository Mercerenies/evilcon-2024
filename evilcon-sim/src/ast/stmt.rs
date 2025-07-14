
use super::identifier::Identifier;
use super::expr::Expr;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Stmt {
  ExprStmt(Box<Expr>),
  Var(VarStmt),
  Return(Box<Expr>),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct VarStmt {
  pub name: Identifier,
  pub initial_value: Option<Box<Expr>>,
}
