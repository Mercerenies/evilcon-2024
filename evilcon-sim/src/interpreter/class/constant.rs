
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::value::Value;
use crate::interpreter::error::EvalError;

use std::cell::{OnceCell, Cell};
use std::fmt::{Formatter, Debug};

/// Godot doesn't do this, but to make dependency management easier
/// I'm lazy-evaluating all top-level constants. This is mainly for
/// constants whose value is a `preload` call.
///
/// Note: `LazyCell` isn't good enough for what I need here, since the
/// eventual value is parameterized by [`EvaluatorState`].
pub struct LazyConst {
  value: OnceCell<Result<Value, EvalError>>,
  // Invariant: initializer is always Some if the value is
  // uninitialized.
  initializer: Cell<Option<Box<dyn FnOnce(&EvaluatorState) -> Result<Value, EvalError>>>>,
}

impl LazyConst {
  pub fn new<F>(initializer: F) -> Self
  where F: FnOnce(&EvaluatorState) -> Result<Value, EvalError> + 'static {
    Self {
      value: OnceCell::new(),
      initializer: Cell::new(Some(Box::new(initializer))),
    }
  }

  /// If the value has not yet been initialized, initialize it and
  /// return (verbatim) whatever is returned by the initializer. If
  /// the value has been successfully initialized, return that value.
  /// If the value errored while being initialized in the past, return
  /// [`EvalError::PoisonedConstant`].
  pub fn get(&self, state: &EvaluatorState) -> Result<&Value, EvalError> {
    let mut first_init = false;
    let value = self.value.get_or_init(|| {
      let initializer = self.initializer.take().unwrap();
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
