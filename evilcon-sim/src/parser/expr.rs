
use crate::ast::expr::{Expr, AttrTarget, Literal, Lambda, DictEntry};
use crate::ast::expr::operator::AssignOp;
use super::error::ParseError;
use super::base::GdscriptParser;
use super::decl::parse_function_parameters;
use super::stmt::{parse_body, COMMENT_KIND};
use super::sitter::{nth_child, nth_named_child, named_child, validate_kind};

use tree_sitter::Node;

pub const ARGS_KIND: &'static str = "arguments";

pub(super) fn parse_expr(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Expr, ParseError> {
  match node.kind() {
    "string" | "string_name" => {
      let string_lit = parser.string_lit(node)?;
      Ok(Literal::String(string_lit).into())
    }
    "integer" => {
      let raw = parser.utf8_text(node)?;
      let int_lit: i64 = raw.parse().map_err(|_| ParseError::InvalidInt(raw.to_owned()))?;
      Ok(Expr::from(int_lit))
    }
    "float" => {
      let raw = parser.utf8_text(node)?;
      let float_lit: f64 = raw.parse().map_err(|_| ParseError::InvalidFloat(raw.to_owned()))?;
      Ok(Expr::from(float_lit))
    }
    "null" => {
      Ok(Expr::from(Literal::Null))
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
        .filter(|child| child.kind() != COMMENT_KIND)
        .map(|child| parse_expr(parser, child))
        .collect::<Result<_, _>>()?;
      Ok(Expr::Array(elements))
    }
    "dictionary" => {
      let mut cursor = node.walk();
      let elements = node.named_children(&mut cursor)
        .filter(|child| child.kind() != COMMENT_KIND)
        .map(|child| parse_dict_entry(parser, child))
        .collect::<Result<_, _>>()?;
      Ok(Expr::Dictionary(elements))
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

      // Binary operators in GDScript can be multiple words. Take all
      // but the first and last children (which are the operator
      // arguments)
      let op = (1..=(node.child_count() - 2))
        .map(|i| parser.utf8_text(nth_child(node, i)?))
        .collect::<Result<Vec<_>, _>>()?
        .join(" ")
        .parse()?;

      Ok(Expr::BinaryOp(Box::new(lhs), op, Box::new(rhs)))
    }
    "assignment" => {
      let lhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let rhs = parse_expr(parser, nth_named_child(node, 1)?)?;
      let op = AssignOp::default();
      Ok(Expr::AssignOp(Box::new(lhs), op, Box::new(rhs)))
    }
    "augmented_assignment" => {
      let lhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let rhs = parse_expr(parser, nth_named_child(node, 1)?)?;
      let op = parser.utf8_text(nth_child(node, 1)?)?.parse()?;
      Ok(Expr::AssignOp(Box::new(lhs), op, Box::new(rhs)))
    }
    "unary_operator" => {
      let rhs = parse_expr(parser, nth_named_child(node, 0)?)?;
      let op = parser.utf8_text(nth_child(node, 0)?)?;
      if op == "await" {
        Ok(Expr::Await(Box::new(rhs)))
      } else {
        Ok(Expr::UnaryOp(op.parse()?, Box::new(rhs)))
      }
    }
    "parenthesized_expression" => {
      Ok(parse_expr(parser, nth_named_child(node, 0)?)?)
    }
    "conditional_expression" => {
      let if_true = parse_expr(parser, nth_named_child(node, 0)?)?;
      let cond = parse_expr(parser, nth_named_child(node, 1)?)?;
      let if_false = parse_expr(parser, nth_named_child(node, 2)?)?;
      Ok(Expr::Conditional {
        if_true: Box::new(if_true),
        cond: Box::new(cond),
        if_false: Box::new(if_false),
      })
    }
    "lambda" => {
      let lambda = parse_lambda(parser, node)?;
      Ok(Expr::Lambda(lambda))
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

fn parse_dict_entry(
  parser: &GdscriptParser,
  node: Node,
) -> Result<DictEntry, ParseError> {
  assert_eq!(node.kind(), "pair");
  let key = parse_expr(parser, named_child(node, "key")?)?;
  let value = parse_expr(parser, named_child(node, "value")?)?;
  Ok(DictEntry { key, value })
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

fn parse_lambda(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Lambda, ParseError> {
  match node.named_child_count() {
    2 => {
      // Unnamed lambda
      let params = parse_function_parameters(parser, nth_named_child(node, 0).unwrap())?;
      let body = parse_body(parser, nth_named_child(node, 1).unwrap())?;
      Ok(Lambda { name: None, params, body })
    }
    3 => {
      // Named lambda
      let name = parser.identifier(nth_named_child(node, 0).unwrap())?;
      let params = parse_function_parameters(parser, nth_named_child(node, 1).unwrap())?;
      let body = parse_body(parser, nth_named_child(node, 2).unwrap())?;
      Ok(Lambda { name: Some(name), params, body })
    }
    _ => {
      Err(ParseError::MalformedLambda)
    }
  }
}
