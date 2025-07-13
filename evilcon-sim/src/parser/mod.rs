
//! Parser for a subset of GDScript needed to simulate the Evilcon
//! card game.

mod base;
pub mod error;
pub mod sitter;

use base::GdscriptParser;
use error::ParseError;
use sitter::{nth_child_of, is_string_lit};
use crate::ast::file::{SourceFile, ExtendsClause};
use crate::ast::identifier::Identifier;

use tree_sitter::Node;

use std::iter::Peekable;

pub fn read_from_string(s: &str) -> Result<SourceFile, ParseError> {
  let parser = GdscriptParser::from_source(s);
  let root = parser.root_node();
  let mut cursor = parser.cursor();

  println!("{:?}", root.to_sexp());

  if root.kind() != "source" {
    return Err(ParseError::Unexpected {
      expected: String::from("source"),
      actual: root.kind().to_owned(),
    });
  }

  let root_children = root.children(&mut cursor)
    .collect::<Vec<_>>();
  let mut root_children = root_children.into_iter().peekable();

  let mut source_file = SourceFile::new();
  parse_prologue(&parser, &mut source_file, &mut root_children)?;
  // TODO
  Ok(source_file)
}

fn parse_prologue<'tree, I>(
  parser: &GdscriptParser,
  source_file: &mut SourceFile,
  nodes: &mut Peekable<I>,
) -> Result<(), ParseError>
where I: Iterator<Item = Node<'tree>> {
  loop {
    let Some(next_kind) = nodes.peek().map(|node| node.kind()) else {
      break;
    };
    if next_kind != "extends_statement" && next_kind != "class_name_statement" {
      break; // Done with prologue
    }
    let next = nodes.next().unwrap();
    match next.kind() {
      "extends_statement" => {
        source_file.extends_clause = Some(parse_extends_clause(parser, &next)?);
      }
      "class_name_statement" => {
        source_file.class_name = Some(parse_class_name_statement(parser, &next)?);
      }
      _ => unreachable!(),
    }
  }
  Ok(())
}

fn parse_class_name_statement(
  parser: &GdscriptParser,
  node: &Node,
) -> Result<Identifier, ParseError> {
  let name_node = nth_child_of(node, 1, "class_name_statement")?;
  parser.identifier(&name_node)
}

fn parse_extends_clause(
  parser: &GdscriptParser,
  node: &Node,
) -> Result<ExtendsClause, ParseError> {
  let body_node = nth_child_of(node, 1, "extends_statement")?;
  if is_string_lit(&body_node) {
    parser.string_lit(&body_node)
      .map(ExtendsClause::Path)
  } else {
    parser.identifier(&body_node)
      .map(ExtendsClause::Id)
  }
}
