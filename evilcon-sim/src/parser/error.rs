
use thiserror::Error;

use std::str::Utf8Error;

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum ParseError {
  #[error("Unexpected {actual} (expected {expected})")]
  Unexpected { actual: String, expected: String },
  #[error("Missing field {0}")]
  MissingField(String),
  #[error("{0}")]
  Utf8Error(#[from] Utf8Error),
}
