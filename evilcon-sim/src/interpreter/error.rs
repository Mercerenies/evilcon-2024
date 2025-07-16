
use super::value::InvalidHashKey;

use thiserror::Error;

#[derive(Debug, Clone, Error)]
pub enum EvalError {
  #[error("{0}")]
  InvalidHashKey(#[from] InvalidHashKey),
  #[error("Unknown class {0}")]
  UnknownClass(String),
  #[error("Poisoned constant")]
  PoisonedConstant,
}
