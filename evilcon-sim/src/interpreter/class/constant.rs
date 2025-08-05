
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::value::SimpleValue;
use crate::interpreter::error::EvalError;
use crate::ast::expr::Expr;

use std::fmt::{Formatter, Debug};
use std::sync::{Mutex, OnceLock};

/// Godot doesn't do this, but to make dependency management easier
/// I'm lazy-evaluating all top-level constants. This is mainly for
/// constants whose value is a `preload` call.
///
/// Note: `LazyCell` isn't good enough for what I need here, since the
/// eventual value is parameterized by [`EvaluatorState`].
pub struct LazyConst {
  value: OnceLock<Result<SimpleValue, EvalError>>,
  // Invariant: initializer is always Some if the value is
  // uninitialized.
  initializer: Mutex<Option<Box<dyn FnOnce(&EvaluatorState) -> Result<SimpleValue, EvalError> + Send + Sync>>>,
}

impl LazyConst {
  pub fn new<F>(initializer: F) -> Self
  where F: FnOnce(&EvaluatorState) -> Result<SimpleValue, EvalError> + Send + Sync + 'static {
    Self {
      value: OnceLock::new(),
      initializer: Mutex::new(Some(Box::new(initializer))),
    }
  }

  /// A [`LazyConst`] which is already resolved to the given value.
  pub fn resolved(value: SimpleValue) -> Self {
    let cell = OnceLock::new();
    cell.set(Ok(value)).unwrap();
    Self {
      value: cell,
      initializer: Mutex::new(None),
    }
  }

  /// A [`LazyConst`] whose value is already resolved to null.
  pub fn null() -> Self {
    Self::resolved(SimpleValue::Null)
  }

  /// A [`LazyConst`] that evaluates an expression.
  pub fn evaluator(expr: Expr) -> Self {
    Self::new(move |state| {
      let value = state.eval_expr(&expr)?
        .try_into()?;
      Ok(value)
    })
  }

  /// A [`LazyConst`] that preloads a class.
  pub fn preload(class_path: impl Into<String>) -> Self {
    let expr = Expr::call("preload", vec![Expr::string(class_path)]);
    Self::evaluator(expr)
  }

  /// If the value has not yet been initialized, initialize it and
  /// return (verbatim) whatever is returned by the initializer. If
  /// the value has been successfully initialized, return that value.
  /// If the value errored while being initialized in the past, return
  /// [`EvalError::PoisonedConstant`].
  pub fn get(&self, state: &EvaluatorState) -> Result<&SimpleValue, EvalError> {
    let mut first_init = false;
    let value = self.value.get_or_init(|| {
      let mut initializer = self.initializer.lock().unwrap(); // Propagate panics
      let initializer = initializer.take().unwrap(); // Struct invariant guarantees this is Some
      first_init = true;
      initializer(state)
    });
    let value = as_ref_ok(&value);
    if first_init {
      value
    } else {
      value.map_err(|_| EvalError::PoisonedConstant)
    }
  }

  pub fn get_if_initialized(&self) -> Result<Option<&SimpleValue>, EvalError> {
    let Some(value) = self.value.get() else {
      return Ok(None);
    };
    value.as_ref()
      .map(Some)
      .map_err(|_| EvalError::PoisonedConstant)
  }
}

impl Debug for LazyConst {
  fn fmt(&self, f: &mut Formatter) -> std::fmt::Result {
    f.debug_struct("LazyConst")
      .field("value", &self.value)
      .field("initializer", &"<fn>")
      .finish()
  }
}

fn as_ref_ok<T, E: Clone>(value: &Result<T, E>) -> Result<&T, E> {
  value.as_ref().map_err(Clone::clone)
}
