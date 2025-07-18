
use crate::ast::decl::{Decl, FunctionDecl, ConstructorDecl, EnumDecl};
use crate::ast::identifier::Identifier;
use super::error::ParseError;
use super::base::GdscriptParser;
use super::sitter::{named_child, nth_child, validate_kind, is_identifier};
use super::expr::parse_expr;
use super::stmt::{parse_body, parse_var_stmt, COMMENT_KIND};

use tree_sitter::Node;

pub(super) fn parse_decl_seq<'tree>(
  parser: &GdscriptParser,
  nodes: impl IntoIterator<Item = Node<'tree>>,
) -> Result<Vec<Decl>, ParseError> {
  nodes
    .into_iter()
    .filter(|child| child.kind() != COMMENT_KIND)
    .map(|child| parse_decl(parser, child))
    .collect()
}

pub(super) fn parse_decl(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Decl, ParseError> {
  match node.kind() {
    "const_statement" => {
      let name = parser.identifier(named_child(node, "name")?)?;
      let value = parse_expr(parser, named_child(node, "value")?)?;
      Ok(Decl::Const { name, value: Box::new(value) })
    }
    "function_definition" => {
      let function_decl = parse_function_decl(parser, node)?;
      Ok(Decl::Function(function_decl))
    }
    "constructor_definition" => {
      let constructor_decl = parse_constructor_decl(parser, node)?;
      Ok(Decl::Constructor(constructor_decl))
    }
    "variable_statement" => {
      let var_stmt = parse_var_stmt(parser, node)?;
      Ok(Decl::Var(var_stmt))
    }
    "enum_definition" => {
      let enum_decl = parse_enum_decl(parser, node)?;
      Ok(Decl::Enum(enum_decl))
    }
    "class_definition" => {
      let name = parser.identifier(named_child(node, "name")?)?;
      let body = named_child(node, "body")?;
      let body = body.named_children(&mut body.walk())
        .map(|child| parse_decl(parser, child))
        .collect::<Result<Vec<_>, ParseError>>()?;
      Ok(Decl::InnerClass(name, body))
    }
    kind => {
      Err(ParseError::UnknownDecl(kind.to_owned()))
    }
  }
}

fn parse_function_decl(
  parser: &GdscriptParser,
  node: Node,
) -> Result<FunctionDecl, ParseError> {
  let name = parser.identifier(named_child(node, "name")?)?;
  let params = parse_function_parameters(parser, named_child(node, "parameters")?)?;
  let body = parse_body(parser, named_child(node, "body")?)?;
  let is_static = {
    let mut cursor = node.walk();
    let is_static = node.children(&mut cursor).any(|child| child.kind() == "static_keyword");
    is_static
  };
  Ok(FunctionDecl {
    name,
    params,
    body,
    is_static,
  })
}

fn parse_constructor_decl(
  parser: &GdscriptParser,
  node: Node,
) -> Result<ConstructorDecl, ParseError> {
  let params = parse_function_parameters(parser, named_child(node, "parameters")?)?;
  let body = parse_body(parser, named_child(node, "body")?)?;
  Ok(ConstructorDecl {
    params,
    body,
  })
}

pub(super) fn parse_function_parameters(
  parser: &GdscriptParser,
  node: Node,
) -> Result<Vec<Identifier>, ParseError> {
  validate_kind(node, "parameters")?;
  let mut cursor = node.walk();
  node.named_children(&mut cursor)
    .map(|child| {
      if is_identifier(child) {
        // Simple identifier.
        parser.identifier(child)
      } else {
        // Typed parameter. We don't care about the type, so just
        // parse the name.
        let name = nth_child(child, 0)?;
        parser.identifier(name)
      }
    })
    .collect()
}

fn parse_enum_decl(
  parser: &GdscriptParser,
  node: Node,
) -> Result<EnumDecl, ParseError> {
  let name = parser.identifier(named_child(node, "name")?)?;
  let body = named_child(node, "body")?;
  validate_kind(body, "enumerator_list")?;
  let members = body.named_children(&mut body.walk())
    .map(|child| {
      let left = parser.identifier(named_child(child, "left")?)?;
      let right = child.child_by_field_name("right")
        .map(|r| parse_expr(parser, r))
        .transpose()?;
      Ok((left, right))
    })
    .collect::<Result<Vec<_>, ParseError>>()?;
  Ok(EnumDecl {
    name,
    members,
  })
}
