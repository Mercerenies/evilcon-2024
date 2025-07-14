
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
    "integer" => {
      let raw = parser.utf8_text(node)?;
      let int_lit: i64 = raw.parse().map_err(|_| ParseError::InvalidInt(raw.to_owned()))?;
      Ok(Expr::from(int_lit))
    }
    "true" => {
      Ok(Expr::from(true))
    }
    "false" => {
      Ok(Expr::from(false))
    }
    "identifier" => {
      let ident = parser.identifier(node)?;
      Ok(Expr::Name(ident))
    }
    "array" => {
      let mut cursor = node.walk();
      let elements = node.named_children(&mut cursor)
        .map(|child| parse_expr(parser, child))
        .collect::<Result<_, _>>()?;
      Ok(Expr::Array(elements))
    }
    kind => {
      Err(ParseError::UnknownExpr(kind.to_owned()))
    }
  }
}
