
use super::value::InvalidHashKey;

use thiserror::Error;

#[derive(Debug, Clone, Error)]
pub enum EvalError {
  #[error("{0}")]
  InvalidHashKey(#[from] InvalidHashKey),
}
