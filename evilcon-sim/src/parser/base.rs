
use super::sitter::gdscript_tree_sitter_parser;
use crate::ast::identifier::Identifier;

use tree_sitter::{Tree, TreeCursor, Node};

use std::str::Utf8Error;

#[derive(Debug)]
pub(super) struct GdscriptParser<'s> {
  source_code: &'s str,
  tree: Tree,
}

impl<'s> GdscriptParser<'s> {
  pub(super) fn new(source_code: &'s str, tree: Tree) -> Self {
    Self { source_code, tree }
  }

  pub(super) fn from_source(source_code: &'s str) -> Self {
    let mut raw_parser = gdscript_tree_sitter_parser();
    let tree = raw_parser.parse(source_code, None)
      .expect("Failed to parse GDScript source code");
    Self::new(source_code, tree)
  }

  pub(super) fn root_node(&self) -> Node<'_> {
    self.tree.root_node()
  }

  /// See [`Tree::walk`].
  pub(super) fn cursor(&self) -> TreeCursor<'_> {
    self.tree.walk()
  }

  pub(super) fn identifier(&self, node: &Node) -> Result<Identifier, Utf8Error> {
    let id_text = node.utf8_text(self.source_code.as_bytes())?;
    Ok(Identifier(id_text.to_owned()))
  }
}
