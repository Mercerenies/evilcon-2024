
use crate::ast::stmt::{Stmt, VarStmt};
use super::sitter::{validate_kind, nth_child, named_child};
use super::error::ParseError;
use super::base::GdscriptParser;
use super::expr::parse_expr;

use tree_sitter::Node;

pub(super) const BODY_KIND: &str = "body";
pub(super) const COMMENT_KIND: &str = "comment";

pub(super) fn parse_body(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Vec<Stmt>, ParseError> {
  validate_kind(node, BODY_KIND)?;
  let mut cursor = node.walk();
  node.children(&mut cursor)
    .filter(|child| child.kind() != COMMENT_KIND)
    .map(|child| parse_stmt(parser, child))
    .collect()
}

pub(super) fn parse_stmt(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Stmt, ParseError> {
  match node.kind() {
    "expression_statement" => {
      let value = parse_expr(parser, nth_child(node, 0)?)?;
      Ok(Stmt::ExprStmt(Box::new(value)))
    }
    "return_statement" => {
      let value = parse_expr(parser, nth_child(node, 1)?)?;
      Ok(Stmt::Return(Box::new(value)))
    }
    "variable_statement" => {
      let var_stmt = parse_var_stmt(parser, node)?;
      Ok(Stmt::Var(var_stmt))
    }
    kind => {
      Err(ParseError::UnknownStmt(kind.to_owned()))
    }
  }
}

pub(super) fn parse_var_stmt(
  parser: &GdscriptParser,
  node: Node,
) -> Result<VarStmt, ParseError> {
  assert_eq!(node.kind(), "variable_statement");
  let name = parser.identifier(named_child(node, "name")?)?;
  let value = named_child(node, "value").ok()
    .map(|child| parse_expr(parser, child).map(Box::new))
    .transpose()?;
  Ok(VarStmt { name, initial_value: value })
}
