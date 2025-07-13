
use crate::ast::string::StringLitFromStrError;

use thiserror::Error;

use std::str::Utf8Error;

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum ParseError {
  #[error("Unexpected {actual} (expected {expected})")]
  Unexpected { actual: String, expected: String },
  #[error("Missing field {0}")]
  MissingField(String),
  #[error("Expected argument {index} to '{kind}'")]
  ExpectedArg { index: usize, kind: String },
  #[error("{0}")]
  Utf8Error(#[from] Utf8Error),
  #[error("Error parsing string literal: {0}")]
  StringError(#[from] StringLitFromStrError),
}
