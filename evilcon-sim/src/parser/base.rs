
use super::sitter::{gdscript_tree_sitter_parser, STRING_KINDS, IDENTIFIER_KINDS,
                    validate_kind_any};
use super::error::ParseError;
use crate::ast::identifier::Identifier;
use crate::ast::string::GdString;

use tree_sitter::{Tree, TreeCursor, Node};

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

  pub(super) fn utf8_text(&self, node: Node) -> Result<&str, ParseError> {
    Ok(node.utf8_text(self.source_code.as_bytes())?)
  }

  pub(super) fn identifier(&self, node: Node) -> Result<Identifier, ParseError> {
    validate_kind_any(node, IDENTIFIER_KINDS)?;
    let id_text = node.utf8_text(self.source_code.as_bytes())?;
    Ok(Identifier(id_text.to_owned()))
  }

  pub(super) fn string_lit(&self, node: Node) -> Result<GdString, ParseError> {
    validate_kind_any(node, STRING_KINDS)?;
    Ok(node.utf8_text(self.source_code.as_bytes())?.parse()?)
  }
}
