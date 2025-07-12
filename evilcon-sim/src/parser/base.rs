
use super::sitter::gdscript_tree_sitter_parser;

use tree_sitter::{Tree, TreeCursor, Node};
use tree_sitter::ffi::TSTreeCursor;

use std::pin::Pin;
use std::marker::PhantomPinned;
use std::ops::Deref;

#[derive(Debug)]
pub(super) struct GdscriptParser<'s> {
  source_code: &'s str,
  tree: Pin<Box<PinnedTree>>,
  // safety: References only self.root, which is valid for the entire
  // lifetime of self.
  cursor: TSTreeCursor,
}

#[derive(Debug)]
struct PinnedTree {
  tree: Tree,
  _unpin: PhantomPinned,
}

impl<'s> GdscriptParser<'s> {
  pub(super) fn new(source_code: &'s str) -> Self {
    let mut raw_parser = gdscript_tree_sitter_parser();
    let tree = raw_parser.parse(source_code, None)
      .expect("Failed to parse GDScript source code");
    let tree = Box::pin(PinnedTree { tree, _unpin: PhantomPinned });
    let cursor = tree.walk().into_raw();
    Self { source_code, tree, cursor }
  }

  pub(super) fn root_node(&self) -> Node<'_> {
    self.tree.root_node()
  }

  pub(super) fn cursor(&mut self) -> &mut TreeCursor<'_> {
    // safety: `self.cursor` always references pinned data in `self`.
    unsafe {
      TreeCursor::from_raw(self.cursor)
    }
  }
}

impl<'s> Drop for GdscriptParser<'s> {
  fn drop(&mut self) {
    // safety: `self.cursor` always references pinned data in `self`.
    unsafe {
      let cursor = TreeCursor::from_raw(self.cursor);
    }
  }
}

impl Deref for PinnedTree {
  type Target = Tree;

  fn deref(&self) -> &Self::Target {
    &self.tree
  }
}
