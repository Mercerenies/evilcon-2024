
//! Primitives for accessing the `tree_sitter` GDScript parser.

use tree_sitter::Parser;
use tree_sitter_gdscript::LANGUAGE;

pub fn gdscript_tree_sitter_parser() -> Parser {
  let mut parser = Parser::new();
  parser.set_language(&LANGUAGE.into())
    .expect("Failed to parse GDScript grammar");
  parser
}
