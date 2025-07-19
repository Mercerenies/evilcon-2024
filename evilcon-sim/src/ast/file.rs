
use super::identifier::Identifier;
use super::string::GdString;
use super::decl::Decl;

use std::borrow::Cow;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
pub struct SourceFile {
  pub extends_clause: Option<ExtendsClause>,
  pub class_name: Option<Identifier>,
  pub decls: Vec<Decl>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ExtendsClause {
  Id(Identifier),
  Path(GdString),
}

impl SourceFile {
  pub fn new() -> Self {
    Default::default()
  }

  pub fn extends_clause_or_default(&self) -> Cow<'_, ExtendsClause> {
    match &self.extends_clause {
      None => Cow::Owned(ExtendsClause::Id(Identifier(String::from("RefCounted")))),
      Some(c) => Cow::Borrowed(c),
    }
  }
}

impl Default for ExtendsClause {
  fn default() -> Self {
    ExtendsClause::Id(Identifier(String::from("RefCounted")))
  }
}
