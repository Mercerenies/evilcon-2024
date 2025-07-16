
use super::value::{Value, InvalidHashKey, NoSuchVar, NoSuchFunc};
use crate::ast::expr::Expr;

use thiserror::Error;

#[derive(Debug, Clone)]
pub enum EvalErrorOrControlFlow {
  EvalError(EvalError),
  ControlFlow(ControlFlow),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ControlFlow {
  Break,
  Continue,
  Return(Value),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum LoopControlFlow {
  Break,
  Continue,
}

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
  #[error("Unexpected GetNode {0}")]
  UnexpectedGetNode(String),
  #[error("Wrong number of arguments, got {actual} but expected {expected}")]
  WrongArity { actual: usize, expected: usize },
  #[error("Unexpected control flow {0:?}")]
  UnexpectedControlFlow(ControlFlow),
  #[error("Cannot call {0:?}")]
  CannotCall(Expr),
  #[error("{0:?} is not iterable")]
  CannotIterate(Value),
}

impl ControlFlow {
  pub fn expect_normal<T>(value: Result<T, EvalErrorOrControlFlow>) -> Result<T, EvalError> {
    match value {
      Ok(value) => Ok(value),
      Err(EvalErrorOrControlFlow::EvalError(e)) => Err(e),
      Err(EvalErrorOrControlFlow::ControlFlow(cf)) => Err(EvalError::UnexpectedControlFlow(cf)),
    }
  }

  pub fn expect_return(value: Result<Value, EvalErrorOrControlFlow>) -> Result<Value, EvalError> {
    match value {
      Ok(value) => Ok(value),
      Err(EvalErrorOrControlFlow::EvalError(e)) => Err(e),
      Err(EvalErrorOrControlFlow::ControlFlow(ControlFlow::Return(v))) => Ok(v),
      Err(EvalErrorOrControlFlow::ControlFlow(cf)) => Err(EvalError::UnexpectedControlFlow(cf)),
    }
  }

  pub fn expect_return_or_null(value: Result<(), EvalErrorOrControlFlow>) -> Result<Value, EvalError> {
    Self::expect_return(value.map(|_| Value::Null))
  }

  pub fn extract_loop_control(value: Result<(), EvalErrorOrControlFlow>) -> Result<Option<LoopControlFlow>, EvalErrorOrControlFlow> {
    match value {
      Err(EvalErrorOrControlFlow::ControlFlow(ControlFlow::Break)) => Ok(Some(LoopControlFlow::Break)),
      Err(EvalErrorOrControlFlow::ControlFlow(ControlFlow::Continue)) => Ok(Some(LoopControlFlow::Continue)),
      Ok(()) => Ok(None),
      Err(err) => Err(err),
    }
  }
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

impl From<EvalError> for EvalErrorOrControlFlow {
  fn from(e: EvalError) -> Self {
    EvalErrorOrControlFlow::EvalError(e)
  }
}

impl From<ControlFlow> for EvalErrorOrControlFlow {
  fn from(e: ControlFlow) -> Self {
    EvalErrorOrControlFlow::ControlFlow(e)
  }
}
