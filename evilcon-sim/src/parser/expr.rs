
use crate::ast::expr::{Expr, AttrTarget, Literal};
use super::error::ParseError;
use super::base::GdscriptParser;
use super::sitter::{nth_child, nth_named_child, validate_kind};

use tree_sitter::Node;

pub const ARGS_KIND: &'static str = "arguments";

pub(super) fn parse_expr(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Expr, ParseError> {
  match node.kind() {
    "string" => {
      let string_lit = parser.string_lit(node)?;
      Ok(Literal::String(string_lit).into())
    }
    "integer" => {
      let raw = parser.utf8_text(node)?;
      let int_lit: i64 = raw.parse().map_err(|_| ParseError::InvalidInt(raw.to_owned()))?;
      Ok(Expr::from(int_lit))
    }
    "true" => {
      Ok(Expr::from(true))
    }
    "false" => {
      Ok(Expr::from(false))
    }
    "identifier" => {
      let ident = parser.identifier(node)?;
      Ok(Expr::Name(ident))
    }
    "array" => {
      let mut cursor = node.walk();
      let elements = node.named_children(&mut cursor)
        .map(|child| parse_expr(parser, child))
        .collect::<Result<_, _>>()?;
      Ok(Expr::Array(elements))
    }
    "call" => {
      let func = parse_expr(parser, nth_named_child(node, 0)?)?;
      let args = parse_args(parser, nth_named_child(node, 1)?)?;
      Ok(Expr::Call { func: Box::new(func), args })
    }
    "subscript" => {
      let lhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let rhs = parse_expr(parser, nth_named_child(node, 1)?)?;
      Ok(Expr::Subscript(Box::new(lhs), Box::new(rhs)))
    }
    "attribute" => {
      parse_attribute(parser, node)
    }
    "binary_operator" => {
      let lhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let rhs = parse_expr(parser, nth_named_child(node, 1)?)?;
      let op = parser.utf8_text(nth_child(node, 1)?)?.parse()?;
      Ok(Expr::BinaryOp(Box::new(lhs), op, Box::new(rhs)))
    }
    "augmented_assignment" => {
      let lhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let rhs = parse_expr(parser, nth_named_child(node, 1)?)?;
      let op = parser.utf8_text(nth_child(node, 1)?)?.parse()?;
      Ok(Expr::AssignOp(Box::new(lhs), op, Box::new(rhs)))
    }
    "unary_operator" => {
      let rhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let op = parser.utf8_text(nth_child(node, 0)?)?.parse()?;
      Ok(Expr::UnaryOp(op, Box::new(rhs)))
    }
    "parenthesized_expression" => {
      Ok(parse_expr(parser, nth_named_child(node, 0)?)?)
    }
    kind => {
      Err(ParseError::UnknownExpr(kind.to_owned()))
    }
  }
}

fn parse_args(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Vec<Expr>, ParseError> {
  validate_kind(node, ARGS_KIND)?;
  let mut cursor = node.walk();
  node.named_children(&mut cursor)
    .map(|child| parse_expr(parser, child))
    .collect()
}

fn parse_attribute(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Expr, ParseError> {
  assert_eq!(node.kind(), "attribute");
  let mut cursor = node.walk();
  let mut args = node.named_children(&mut cursor);
  let Some(lhs) = args.next() else {
    return Err(ParseError::ExpectedArg { index: 0, kind: "attribute".to_owned() });
  };
  let lhs = parse_expr(parser, lhs)?;
  args.try_fold(lhs, |lhs, rhs| {
    let rhs = parse_attribute_rhs(parser, rhs)?;
    Ok(lhs.attr(rhs))
  })
}

fn parse_attribute_rhs(
  parser: &GdscriptParser,
  node: Node,
) -> Result<AttrTarget, ParseError> {
  match node.kind() {
    "identifier" => {
      let id = parser.identifier(node)?;
      Ok(AttrTarget::Name(id))
    }
    "attribute_subscript" => {
      let name = parser.identifier(nth_named_child(node, 0)?)?;
      let key = parse_expr(parser, nth_named_child(node, 1)?)?;
      Ok(AttrTarget::Subscript(name, Box::new(key)))
    }
    "attribute_call" => {
      let name = parser.identifier(nth_named_child(node, 0)?)?;
      let args = parse_args(parser, nth_named_child(node, 1)?)?;
      Ok(AttrTarget::Call(name, args))
    }
    kind => {
      Err(ParseError::UnknownExpr(kind.to_owned()))
    }
  }
}
