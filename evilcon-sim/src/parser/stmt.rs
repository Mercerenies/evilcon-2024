
use crate::ast::stmt::{Stmt, VarStmt, IfStmt, ElifClause};
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
    "if_statement" => {
      let if_stmt = parse_if_stmt(parser, node)?;
      Ok(Stmt::If(if_stmt))
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

pub(super) fn parse_if_stmt(
  parser: &GdscriptParser,
  node: Node,
) -> Result<crate::ast::stmt::IfStmt, ParseError> {
  assert_eq!(node.kind(), "if_statement");
  let mut cursor = node.walk();

  let condition = parse_expr(parser, named_child(node, "condition")?)?;
  let body = parse_body(parser, named_child(node, "body")?)?;

  let mut elif_clauses = Vec::new();
  let mut else_clause = None;
  for alt in node.children_by_field_name("alternative", &mut cursor) {
    match alt.kind() {
      "elif_clause" => {
        let condition = parse_expr(parser, named_child(alt, "condition")?)?;
        let body = parse_body(parser, named_child(alt, "body")?)?;
        elif_clauses.push(ElifClause { condition: Box::new(condition), body });
      }
      "else_clause" => {
        assert!(else_clause.is_none(), "Got two else clauses in one if statement");
        else_clause = Some(parse_body(parser, named_child(alt, "body")?)?);
      }
      kind => {
        Err(ParseError::UnknownClause(kind.to_owned()))?
      }
    }
  }
  Ok(IfStmt {
    condition: Box::new(condition),
    body,
    elif_clauses,
    else_clause,
  })
}
