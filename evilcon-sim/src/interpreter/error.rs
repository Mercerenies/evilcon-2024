
use super::value::{InvalidHashKey, NoSuchVar, NoSuchFunc};

use thiserror::Error;

#[derive(Debug, Clone, Error)]
pub enum EvalError {
  #[error("{0}")]
  InvalidHashKey(#[from] InvalidHashKey),
  #[error("Unknown class {0}")]
  UnknownClass(String),
  #[error("Poisoned constant")]
  PoisonedConstant,
  #[error("Undefined variable {0}")]
  UndefinedVariable(String),
  #[error("Unknown function {0}")]
  UndefinedFunc(String),
}

impl From<NoSuchVar> for EvalError {
  fn from(e: NoSuchVar) -> Self {
    EvalError::UndefinedVariable(e.0)
  }
}

impl From<NoSuchFunc> for EvalError {
  fn from(e: NoSuchFunc) -> Self {
    EvalError::UndefinedFunc(e.0)
  }
}
