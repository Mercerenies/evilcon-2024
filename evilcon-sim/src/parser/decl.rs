
use crate::ast::decl::{Decl, FunctionDecl};
use crate::ast::identifier::Identifier;
use super::error::ParseError;
use super::base::GdscriptParser;
use super::sitter::{named_child, nth_child, validate_kind, is_identifier};
use super::expr::parse_expr;
use super::stmt::{parse_body, parse_var_stmt, COMMENT_KIND};

use tree_sitter::Node;

pub(super) fn parse_decl_seq<'tree>(
  parser: &GdscriptParser,
  nodes: impl IntoIterator<Item = Node<'tree>>,
) -> Result<Vec<Decl>, ParseError> {
  nodes
    .into_iter()
    .filter(|child| child.kind() != COMMENT_KIND)
    .map(|child| parse_decl(parser, child))
    .collect()
}

pub(super) fn parse_decl(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Decl, ParseError> {
  match node.kind() {
    "const_statement" => {
      let name = parser.identifier(named_child(node, "name")?)?;
      let value = parse_expr(parser, named_child(node, "value")?)?;
      Ok(Decl::Const { name, value: Box::new(value) })
    }
    "function_definition" => {
      let function_decl = parse_function_decl(parser, node)?;
      Ok(Decl::Function(function_decl))
    }
    "variable_statement" => {
      let var_stmt = parse_var_stmt(parser, node)?;
      Ok(Decl::Var(var_stmt))
    }
    kind => {
      Err(ParseError::UnknownDecl(kind.to_owned()))
    }
  }
}

fn parse_function_decl(
  parser: &GdscriptParser,
  node: Node,
) -> Result<FunctionDecl, ParseError> {
  let name = parser.identifier(named_child(node, "name")?)?;
  let params = parse_function_parameters(parser, named_child(node, "parameters")?)?;
  let body = parse_body(parser, named_child(node, "body")?)?;
  Ok(FunctionDecl {
    name,
    params,
    body,
  })
}

pub(super) fn parse_function_parameters(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Vec<Identifier>, ParseError> {
  validate_kind(node, "parameters")?;
  let mut cursor = node.walk();
  node.named_children(&mut cursor)
    .map(|child| {
      if is_identifier(child) {
        // Simple identifier.
        parser.identifier(child)
      } else {
        // Typed parameter. We don't care about the type, so just
        // parse the name.
        let name = nth_child(child, 0)?;
        parser.identifier(name)
      }
    })
    .collect()
}
