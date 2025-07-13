
use crate::ast::decl::Decl;
use super::error::ParseError;
use super::base::GdscriptParser;
use super::sitter::named_child;
use super::expr::parse_expr;

use tree_sitter::Node;

pub(super) fn parse_decl(
  parser: &GdscriptParser,
  node: &Node,
) -> Result<Decl, ParseError> {
  match node.kind() {
    "const_statement" => {
      let name = parser.identifier(&named_child(node, "name")?)?;
      let value = parse_expr(parser, &named_child(node, "value")?)?;
      Ok(Decl::Const { name, value })
    }
    kind => {
      Err(ParseError::UnknownDecl(kind.to_owned()))
    }
  }
}
