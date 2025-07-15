
use crate::ast::string::StringLitFromStrError;
use crate::ast::expr::operator::OpFromStrError;

use thiserror::Error;

use std::str::Utf8Error;
use std::fmt::{self, Display, Formatter};

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum ParseError {
  #[error("{0}")]
  Unexpected(Unexpected),
  #[error("Missing field {0}")]
  MissingField(String),
  #[error("Expected argument {index} to '{kind}'")]
  ExpectedArg { index: usize, kind: String },
  #[error("{0}")]
  Utf8Error(#[from] Utf8Error),
  #[error("Error parsing string literal: {0}")]
  StringError(#[from] StringLitFromStrError),
  #[error("Invalid integer literal {0:?}")]
  InvalidInt(String),
  #[error("Unknown declaration type {0}")]
  UnknownDecl(String),
  #[error("Unknown expression type {0}")]
  UnknownExpr(String),
  #[error("Unknown statement type {0}")]
  UnknownStmt(String),
  #[error("Unknown clause type {0}")]
  UnknownClause(String),
  #[error("{0}")]
  OpError(#[from] OpFromStrError),
}

#[derive(Debug, Clone)]
pub struct Unexpected {
  pub actual: String,
  pub expected: Vec<String>,
}

impl Unexpected {
  pub fn new(actual: impl Into<String>, expected: impl IntoIterator<Item = impl Into<String>>) -> Self {
    let actual = actual.into();
    let expected = expected.into_iter().map(|s| s.into()).collect();
    Unexpected { actual, expected }
  }

  pub fn single(actual: impl Into<String>, expected: impl Into<String>) -> Self {
    Self::new(actual, [expected])
  }
}

impl Display for Unexpected {
  fn fmt(&self, f: &mut Formatter) -> fmt::Result {
    if self.expected.len() < 2 {
      write!(f, "Unexpected {} (expected {})", self.actual, self.expected[0])
    } else {
      write!(f, "Unexpected {} (expected one of {})", self.actual, self.expected.join(", "))
    }
  }
}

impl From<Unexpected> for ParseError {
  fn from(e: Unexpected) -> Self {
    ParseError::Unexpected(e)
  }
}
