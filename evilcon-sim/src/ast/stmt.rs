
use super::expr::Expr;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Stmt {
  ExprStmt(Box<Expr>),
  Return(Box<Expr>),
}
