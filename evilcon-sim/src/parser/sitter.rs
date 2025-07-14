
//! Primitives for accessing the `tree_sitter` GDScript parser.

use super::error::{ParseError, Unexpected};

use tree_sitter::{Parser, Node};
use tree_sitter_gdscript::LANGUAGE;

pub const IDENTIFIER_KINDS: [&str; 2] = ["name", "identifier"];
pub const STRING_KIND: &str = "string";

pub fn gdscript_tree_sitter_parser() -> Parser {
  let mut parser = Parser::new();
  parser.set_language(&LANGUAGE.into())
    .expect("Failed to parse GDScript grammar");
  parser
}

pub fn is_identifier(node: Node) -> bool {
  let kind = node.kind();
  IDENTIFIER_KINDS.iter().any(|identifier_kind| identifier_kind == &kind)
}

pub fn is_string_lit(node: Node) -> bool {
  node.kind() == STRING_KIND
}

pub fn validate_kind_any<'a>(node: Node, expected_kinds: impl IntoIterator<Item = &'a str>) -> Result<(), ParseError> {
  let expected_kinds = expected_kinds.into_iter().collect::<Vec<_>>();
  let node_kind = node.kind();
  if expected_kinds.iter().any(|expected_kind| expected_kind == &node_kind) {
    Ok(())
  } else {
    Err(ParseError::Unexpected(Unexpected::new(node.kind(), expected_kinds)))
  }
}

pub fn validate_kind(node: Node, expected_kind: &str) -> Result<(), ParseError> {
  validate_kind_any(node, [expected_kind])
}

pub fn nth_child<'tree>(node: Node<'tree>, idx: usize) -> Result<Node<'tree>, ParseError> {
  let Some(child_node) = node.child(idx) else {
    return Err(ParseError::ExpectedArg { index: idx, kind: node.kind().to_owned() });
  };
  Ok(child_node)
}

pub fn nth_child_of<'tree>(node: Node<'tree>, idx: usize, expected_kind: &str) -> Result<Node<'tree>, ParseError> {
  validate_kind(node, expected_kind)?;
  nth_child(node, idx)
}

pub fn named_child<'tree>(node: Node<'tree>, field_name: &str) -> Result<Node<'tree>, ParseError> {
  node.child_by_field_name(field_name).ok_or_else(|| {
    ParseError::MissingField(field_name.to_owned())
  })
}

pub fn nth_named_child<'tree>(node: Node<'tree>, idx: usize) -> Result<Node<'tree>, ParseError> {
  let Some(child_node) = node.named_child(idx) else {
    return Err(ParseError::ExpectedArg { index: idx, kind: node.kind().to_owned() });
  };
  Ok(child_node)
}
