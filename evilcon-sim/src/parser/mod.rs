
//! Parser for a subset of GDScript needed to simulate the Evilcon
//! card game.

mod base;
pub mod error;
pub mod sitter;

use error::ParseError;
use crate::ast::file::SourceFile;

use tree_sitter::{Tree, TreeCursor, Node};

use std::iter::Peekable;

pub fn read_from_tree(tree: Tree) -> Result<SourceFile, ParseError> {
  let mut cursor = tree.walk();
  let root = tree.root_node();

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
  parse_prologue(&mut source_file, &mut root_children, &mut cursor)?;
  // TODO
  Ok(source_file)
}

pub fn read_from_string(s: &str) -> Result<SourceFile, ParseError> {
  let mut parser = sitter::gdscript_tree_sitter_parser();
  let tree = parser.parse(s, None)
    .expect("Failed to parse GDScript");
  read_from_tree(tree)
}

fn parse_prologue<'tree, I>(
  source_file: &mut SourceFile,
  nodes: &mut Peekable<I>,
  cursor: &mut TreeCursor<'tree>,
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
        source_file.class_name = Some(parse_class_name_statement(&next, cursor)?);
      }
      _ => unreachable!(),
    }
  }
  Ok(())
}

fn parse_class_name_statement<'tree>(
  node: &Node<'tree>,
  cursor: &mut TreeCursor<'tree>,
) -> Result<String, ParseError> {
  let Some(name_node) = node.child(1) else {
    return Err(ParseError::MissingField("name".to_owned()));
  };
  dbg!(name_node);
  todo!()
}
