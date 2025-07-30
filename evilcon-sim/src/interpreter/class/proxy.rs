
//! Proxy fields API.

use crate::interpreter::value::Value;
use crate::interpreter::error::EvalError;
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::operator::expect_int;
use crate::util::clamp;

/// A proxy field is a pseudo-field on a class which calls a Rust
/// method when it is accessed or assigned to. These are not available
/// in the pure GDScript interpreter portion of this engine and are
/// only used for mocking.
pub trait ProxyField {
  fn get_field(&self, state: &mut EvaluatorState) -> Result<Value, EvalError>;
  fn set_field(&mut self, state: &mut EvaluatorState, value: Value) -> Result<(), EvalError>;
}

/// A proxy field which is backed by a real variable. The getter
/// simply returns the variable's value, and the setter assigns a
/// (possibly-modified) version of the value.
pub struct BackedField {
  field_value: Value,
  value_adjustment: Box<dyn FnMut(Value) -> Result<Value, EvalError>>,
}

impl BackedField {
  pub fn new(initial_value: Value) -> Self {
    Self {
      field_value: initial_value,
      value_adjustment: Box::new(Ok),
    }
  }

  pub fn with_adjustment(
    mut self,
    value_adjustment: impl FnMut(Value) -> Result<Value, EvalError> + 'static,
  ) -> Self {
    self.value_adjustment = Box::new(value_adjustment);
    self
  }

  /// Adjustment which clamps integer values within the given range.
  /// Non-integers produce a type error.
  pub fn clamped(self, min: i64, max: i64) -> Self {
    self.with_adjustment(move |value| {
      let value = expect_int(&value)?;
      Ok(Value::from(clamp(value, min, max)))
    })
  }
}

impl ProxyField for BackedField {
  fn get_field(&self, _: &mut EvaluatorState) -> Result<Value, EvalError> {
    Ok(self.field_value.clone())
  }

  fn set_field(&mut self, _: &mut EvaluatorState, value: Value) -> Result<(), EvalError> {
    self.field_value = (self.value_adjustment)(value)?;
    Ok(())
  }
}
