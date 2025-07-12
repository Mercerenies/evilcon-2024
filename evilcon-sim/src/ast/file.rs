
use super::identifier::Identifier;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
pub struct SourceFile {
  pub extends_clause: Option<ExtendsClause>,
  pub class_name: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ExtendsClause {
  Id(Identifier),
  Path(String),
}

impl SourceFile {
  pub fn new() -> Self {
    Default::default()
  }
}
