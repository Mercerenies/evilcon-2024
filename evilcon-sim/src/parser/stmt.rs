
use crate::ast::stmt::Stmt;
use super::sitter::{validate_kind, nth_child};
use super::error::ParseError;
use super::base::GdscriptParser;
use super::expr::parse_expr;

use tree_sitter::Node;

pub(super) const BODY_KIND: &str = "body";

pub(super) fn parse_body(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Vec<Stmt>, ParseError> {
  validate_kind(node, BODY_KIND)?;
  let mut cursor = node.walk();
  node.children(&mut cursor)
    .map(|child| parse_stmt(parser, child))
    .collect()
}

pub(super) fn parse_stmt(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Stmt, ParseError> {
  match node.kind() {
    "return_statement" => {
      let value = parse_expr(parser, nth_child(node, 1)?)?;
      Ok(Stmt::Return(Box::new(value)))
    }
    kind => {
      Err(ParseError::UnknownStmt(kind.to_owned()))
    }
  }
}
