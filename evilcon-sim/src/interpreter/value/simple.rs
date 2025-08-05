
use super::Value;
use crate::ast::identifier::Identifier;
use crate::interpreter::class::Class;

use ordered_float::OrderedFloat;
use thiserror::Error;
use ordermap::OrderMap;

use std::sync::Arc;

/// A simple value that can safely be shared across threads. This is a
/// subset of the [`Value`] struct which is guaranteed to be
/// immutable.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub enum SimpleValue {
  #[default]
  Null,
  Bool(bool),
  Int(i64),
  Float(OrderedFloat<f64>),
  String(String),
  ClassRef(Arc<Class>),
  EnumType(OrderMap<Identifier, i64>),
}

#[derive(Debug, Clone, Error)]
#[error("Not a simple value {0:?}")]
pub struct InvalidSimpleValue(pub String);

impl From<SimpleValue> for Value {
  fn from(s: SimpleValue) -> Self {
    match s {
      SimpleValue::Null => Value::Null,
      SimpleValue::Bool(b) => Value::Bool(b),
      SimpleValue::Int(i) => Value::Int(i),
      SimpleValue::Float(f) => Value::Float(f),
      SimpleValue::String(s) => Value::String(s),
      SimpleValue::ClassRef(c) => Value::ClassRef(c),
      SimpleValue::EnumType(e) => Value::EnumType(e),
    }
  }
}

impl TryFrom<Value> for SimpleValue {
  type Error = InvalidSimpleValue;

  fn try_from(v: Value) -> Result<Self, Self::Error> {
    Ok(match v {
      Value::Null => SimpleValue::Null,
      Value::Bool(b) => SimpleValue::Bool(b),
      Value::Int(i) => SimpleValue::Int(i),
      Value::Float(f) => SimpleValue::Float(f),
      Value::String(s) => SimpleValue::String(s),
      Value::ClassRef(c) => SimpleValue::ClassRef(c),
      Value::EnumType(e) => SimpleValue::EnumType(e),
      _ => return Err(InvalidSimpleValue(v.to_string())),
    })
  }
}

impl From<f64> for SimpleValue {
  fn from(f: f64) -> Self {
    SimpleValue::Float(OrderedFloat(f))
  }
}

impl From<i64> for SimpleValue {
  fn from(i: i64) -> Self {
    SimpleValue::Int(i)
  }
}

impl From<String> for SimpleValue {
  fn from(s: String) -> Self {
    SimpleValue::String(s)
  }
}

impl From<&str> for SimpleValue {
  fn from(s: &str) -> Self {
    SimpleValue::String(s.into())
  }
}
