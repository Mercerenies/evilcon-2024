
//! Primitives for accessing the `tree_sitter` GDScript parser.

use super::error::ParseError;

use tree_sitter::{Parser, Node};
use tree_sitter_gdscript::LANGUAGE;

pub const IDENTIFIER_KIND: &str = "name";
pub const STRING_KIND: &str = "string";

pub fn gdscript_tree_sitter_parser() -> Parser {
  let mut parser = Parser::new();
  parser.set_language(&LANGUAGE.into())
    .expect("Failed to parse GDScript grammar");
  parser
}

pub fn is_identifier(node: &Node) -> bool {
  node.kind() == IDENTIFIER_KIND
}

pub fn is_string_lit(node: &Node) -> bool {
  node.kind() == STRING_KIND
}

pub fn validate_kind(node: &Node, expected_kind: &str) -> Result<(), ParseError> {
  if node.kind() == expected_kind {
    Ok(())
  } else {
    Err(ParseError::Unexpected {
      actual: node.kind().to_owned(),
      expected: expected_kind.to_owned(),
    })
  }
}

pub fn nth_child_of<'tree>(node: &Node<'tree>, idx: usize, expected_kind: &str) -> Result<Node<'tree>, ParseError> {
  validate_kind(&node, expected_kind)?;
  let Some(child_node) = node.child(idx) else {
    return Err(ParseError::ExpectedArg { index: idx, kind: expected_kind.to_owned() });
  };
  Ok(child_node)
}
