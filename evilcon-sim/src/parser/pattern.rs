
use crate::ast::pattern::Pattern;
use super::error::ParseError;
use super::base::GdscriptParser;
use super::expr::try_parse_literal;

use tree_sitter::Node;

pub(super) fn parse_pattern(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Pattern, ParseError> {
  if let Some(literal) = try_parse_literal(parser, node)? {
    return Ok(Pattern::from(literal));
  }
  match node.kind() {
    "underscore" => {
      Ok(Pattern::Underscore)
    }
    kind => {
      Err(ParseError::UnknownPattern(kind.to_owned()))
    }
  }
}
