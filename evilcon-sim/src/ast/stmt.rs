
use super::expr::Expr;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Stmt {
  Return(Box<Expr>),
}
