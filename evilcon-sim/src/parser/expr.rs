
use crate::ast::expr::{Expr, Literal};
use super::error::ParseError;
use super::base::GdscriptParser;

use tree_sitter::Node;

pub(super) fn parse_expr(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Expr, ParseError> {
  match node.kind() {
    "string" => {
      let string_lit = parser.string_lit(node)?;
      Ok(Literal::String(string_lit).into())
    }
    "identifier" => {
      let ident = parser.identifier(node)?;
      Ok(Expr::Name(ident))
    }
    kind => {
      Err(ParseError::UnknownExpr(kind.to_owned()))
    }
  }
}
