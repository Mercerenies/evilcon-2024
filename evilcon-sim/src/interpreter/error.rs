
use super::value::{Value, InvalidHashKey, NoSuchVar, NoSuchFunc};
use crate::ast::expr::Expr;
use crate::ast::string::formatter::FormatterError;

use thiserror::Error;

use std::fmt::{self, Display, Formatter};

/// A string representation of a [`Value`].
pub type ValueString = String;

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
  #[error("Error in function '{function}'")]
  ErrorInFunction { function: String, #[source] inner: Box<EvalError> },
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
  #[error("Unknown class {0}")]
  UndefinedClass(String),
  #[error("Unexpected GetNode {0}")]
  UnexpectedGetNode(String),
  #[error("Wrong number of arguments, got {actual} but expected {expected}")]
  WrongArity { actual: usize, expected: ExpectedArity },
  #[error("Unexpected control flow {0}")]
  UnexpectedControlFlow(String),
  #[error("Cannot call {0:?}")]
  CannotCall(Expr),
  #[error("Cannot call {0:?}")]
  CannotCallValue(ValueString),
  #[error("{0:?} is not iterable")]
  CannotIterate(ValueString),
  #[error("{0:?} is not assignable")]
  CannotAssignTo(Expr),
  #[error("Type error: Expected {expected_type}, got {value:?}")]
  TypeError { expected_type: String, value: ValueString },
  #[error("Index {0} out of bounds")]
  IndexOutOfBounds(i64),
  #[error("Invalid enum constant {0:?}")]
  InvalidEnumConstant(Expr),
  #[error("'super' name is not allowed in this context")]
  BadSuper,
  #[error("Domain error: {0}")]
  DomainError(String),
  #[error("Formatter error: {0}")]
  FormatterError(#[from] FormatterError),
  #[error("Numerical parse error on {0}")]
  NumberParseError(String),
  #[error("Method intentionally unimplemented: {0}")]
  UnimplementedMethod(String),
}

#[derive(Debug, Clone)]
pub enum ExpectedArity {
  Exactly(usize),
  /// Note: Callers should consider using [`ExpectedArity::between`]
  /// instead, which gracefully degrades to `Exactly` in degenerate
  /// cases.
  Between(usize, usize),
  AtLeast(usize),
}

impl EvalError {
  pub fn type_error(expected: impl Into<String>, value: Value) -> Self {
    Self::TypeError {
      expected_type: expected.into(),
      value: value.to_string(),
    }
  }

  pub fn unexpected_control_flow(cf: ControlFlow) -> Self {
    Self::UnexpectedControlFlow(format!("{:?}", cf))
  }

  pub fn domain_error(error: impl Into<String>) -> Self {
    Self::DomainError(error.into())
  }

  pub fn with_function_context(self, function: impl Into<String>) -> Self {
    Self::ErrorInFunction {
      function: function.into(),
      inner: Box::new(self),
    }
  }
}

impl ExpectedArity {
  pub fn between(min: usize, max: usize) -> Self {
    if min == max {
      Self::Exactly(min)
    } else {
      Self::Between(min, max)
    }
  }
}

impl ControlFlow {
  pub fn expect_normal<T>(value: Result<T, EvalErrorOrControlFlow>) -> Result<T, EvalError> {
    match value {
      Ok(value) => Ok(value),
      Err(EvalErrorOrControlFlow::EvalError(e)) => Err(e),
      Err(EvalErrorOrControlFlow::ControlFlow(cf)) => Err(EvalError::unexpected_control_flow(cf)),
    }
  }

  pub fn expect_return(value: Result<Value, EvalErrorOrControlFlow>) -> Result<Value, EvalError> {
    match value {
      Ok(value) => Ok(value),
      Err(EvalErrorOrControlFlow::EvalError(e)) => Err(e),
      Err(EvalErrorOrControlFlow::ControlFlow(ControlFlow::Return(v))) => Ok(v),
      Err(EvalErrorOrControlFlow::ControlFlow(cf)) => Err(EvalError::unexpected_control_flow(cf)),
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

impl Display for ExpectedArity {
  fn fmt(&self, f: &mut Formatter) -> fmt::Result {
    match self {
      ExpectedArity::Exactly(n) => write!(f, "exactly {n}"),
      ExpectedArity::Between(n, m) => write!(f, "between {n} and {m}"),
      ExpectedArity::AtLeast(n) => write!(f, "at least {n}"),
    }
  }
}
