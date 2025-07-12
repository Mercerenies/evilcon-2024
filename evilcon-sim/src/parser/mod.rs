
//! Parser for a subset of GDScript needed to simulate the Evilcon
//! card game.

mod base;
pub mod error;
pub mod sitter;

use base::GdscriptParser;
use error::ParseError;
use crate::ast::file::SourceFile;
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
        //todo!()
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
  let Some(name_node) = node.child(1) else {
    return Err(ParseError::MissingField("name".to_owned()));
  };
  Ok(parser.identifier(&name_node)?)
}
