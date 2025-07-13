
use super::identifier::Identifier;
use super::expr::Expr;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Decl {
  Const { name: Identifier, value: Expr },
}
