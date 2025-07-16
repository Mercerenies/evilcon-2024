
use super::identifier::Identifier;
use super::expr::Expr;
use super::expr::operator::AssignOp;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Stmt {
  ExprStmt(Box<Expr>),
  Var(VarStmt),
  Return(Option<Box<Expr>>),
  If(IfStmt),
  For(ForStmt),
  Pass,
  Break,
  Continue,
  AssignOp(Box<Expr>, AssignOp, Box<Expr>),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct VarStmt {
  pub name: Identifier,
  pub initial_value: Option<Box<Expr>>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IfStmt {
  pub condition: Box<Expr>,
  pub body: Vec<Stmt>,
  pub elif_clauses: Vec<ElifClause>,
  pub else_clause: Option<Vec<Stmt>>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ElifClause {
  pub condition: Box<Expr>,
  pub body: Vec<Stmt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ForStmt {
  pub variable: Identifier,
  pub iterable: Box<Expr>,
  pub body: Vec<Stmt>,
}
