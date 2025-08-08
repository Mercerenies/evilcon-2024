
//! Proxy fields API.

use crate::interpreter::value::Value;
use crate::interpreter::error::EvalError;
use crate::interpreter::eval::SuperglobalState;
use crate::interpreter::operator::expect_int;
use crate::util::clamp;

use std::sync::Arc;

/// A proxy field is a pseudo-field on a class which calls a Rust
/// method when it is accessed or assigned to. These are not available
/// in the pure GDScript interpreter portion of this engine and are
/// only used for mocking.
pub trait ProxyField {
  fn get_field(
    &self,
    superglobals: &Arc<SuperglobalState>,
    object: &Value,
  ) -> Result<Value, EvalError>;
  fn set_field(
    &self,
    superglobals: &Arc<SuperglobalState>,
    object: &Value,
    value: Value,
  ) -> Result<(), EvalError>;
}

/// A proxy field which is backed by a real variable. The getter
/// simply returns the variable's value, and the setter assigns a
/// (possibly-modified) version of the value.
pub struct BackedField<'a> {
  inner_field_name: &'a str,
  value_adjustment: Box<dyn Fn(Value) -> Result<Value, EvalError> + Send + Sync>,
}

impl<'a> BackedField<'a> {
  pub fn new(inner_field_name: &'a str) -> Self {
    Self {
      inner_field_name,
      value_adjustment: Box::new(Ok),
    }
  }

  pub fn with_adjustment(
    mut self,
    value_adjustment: impl Fn(Value) -> Result<Value, EvalError> + Send + Sync + 'static,
  ) -> Self {
    self.value_adjustment = Box::new(value_adjustment);
    self
  }

  /// Adjustment which clamps integer values within the given range.
  /// Non-integers produce a type error.
  pub fn clamped(self, min: i64, max: i64) -> Self {
    self.with_adjustment(move |value| {
      let value = expect_int("(field setter)", &value)?;
      Ok(Value::from(clamp(value, min, max)))
    })
  }

  /// Adjustment which clamps integer values below the given value.
  /// Non-integers produce a type error.
  pub fn clamped_below(self, upper_bound: i64) -> Self {
    self.with_adjustment(move |value| {
      let value = expect_int("(field setter)", &value)?;
      Ok(Value::from(i64::min(upper_bound, value)))
    })
  }

  /// Adjustment which clamps integer values above the given value.
  /// Non-integers produce a type error.
  pub fn clamped_above(self, lower_bound: i64) -> Self {
    self.with_adjustment(move |value| {
      let value = expect_int("(field setter)", &value)?;
      Ok(Value::from(i64::max(lower_bound, value)))
    })
  }
}

impl<'a> ProxyField for BackedField<'a> {
  fn get_field(&self, superglobals: &Arc<SuperglobalState>, object: &Value) -> Result<Value, EvalError> {
    object.get_value_raw(&self.inner_field_name, superglobals)
  }

  fn set_field(&self, _: &Arc<SuperglobalState>, object: &Value, value: Value) -> Result<(), EvalError> {
    let new_value = (self.value_adjustment)(value)?;
    object.set_value_raw(&self.inner_field_name, new_value)?;
    Ok(())
  }
}
