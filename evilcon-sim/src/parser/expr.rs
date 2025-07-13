
use crate::ast::expr::{Expr, Literal};
use super::error::ParseError;
use super::base::GdscriptParser;

use tree_sitter::Node;

pub(super) fn parse_expr(
  parser: &GdscriptParser,
  node: &Node,
) -> Result<Expr, ParseError> {
  match node.kind() {
    "string" => {
      let string_lit = parser.string_lit(node)?;
      Ok(Literal::String(string_lit).into())
    }
    kind => {
      Err(ParseError::UnknownDecl(kind.to_owned()))
    }
  }
}
