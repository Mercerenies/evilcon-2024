
use super::identifier::Identifier;
use super::string::GdString;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
pub struct SourceFile {
  pub extends_clause: Option<ExtendsClause>,
  pub class_name: Option<Identifier>,
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
}
