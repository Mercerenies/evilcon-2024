
use crate::ast::expr::Literal;
use super::class::Class;

use ordered_float::OrderedFloat;
use thiserror::Error;

use std::collections::HashMap;
use std::rc::Rc;
use std::cell::RefCell;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub enum Value {
  #[default]
  Null,
  Bool(bool),
  Int(i64),
  Float(OrderedFloat<f64>),
  String(String),
  ArrayRef(Rc<RefCell<Vec<Value>>>),
  DictRef(Rc<RefCell<HashMap<HashKey, Value>>>),
  ClassRef(Rc<Class>),
  ObjectRef(ObjectPtr),
}

/// Technically, Godot allows *any* language value to be a dictionary
/// key. But I only use a few, and some of these types would be quite
/// annoying to write a coherent `Hash` impl for, so I'm arbitrarily
/// restricting it to a few primitive types.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum HashKey {
  Null,
  Bool(bool),
  Int(i64),
  Float(OrderedFloat<f64>),
  String(String),
}

#[derive(Debug, Clone)]
pub struct ObjectPtr {
  pub value: Rc<RefCell<ObjectInst>>,
}

#[derive(Debug, Clone)]
pub struct ObjectInst {
  pub class: Rc<Class>,
  pub dict: Rc<RefCell<HashMap<String, Value>>>,
}

#[derive(Debug, Clone, Error)]
#[error("Invalid hash key {0:?}")]
pub struct InvalidHashKey(pub Value);

impl PartialEq for ObjectPtr {
  fn eq(&self, other: &Self) -> bool {
    Rc::ptr_eq(&self.value, &other.value)
  }
}

impl Eq for ObjectPtr {}

impl From<Literal> for Value {
  fn from(lit: Literal) -> Self {
    match lit {
      Literal::Null => Value::Null,
      Literal::Bool(b) => Value::Bool(b),
      Literal::Int(i) => Value::Int(i),
      Literal::Float(f) => Value::Float(f),
      Literal::String(s) => Value::String(s.into()),
    }
  }
}

impl From<HashKey> for Value {
  fn from(hk: HashKey) -> Self {
    match hk {
      HashKey::Null => Value::Null,
      HashKey::Bool(b) => Value::Bool(b),
      HashKey::Int(i) => Value::Int(i),
      HashKey::Float(f) => Value::Float(f),
      HashKey::String(s) => Value::String(s),
    }
  }
}

impl TryFrom<Value> for HashKey {
  type Error = InvalidHashKey;

  fn try_from(v: Value) -> Result<Self, Self::Error> {
    Ok(match v {
      Value::Null => HashKey::Null,
      Value::Bool(b) => HashKey::Bool(b),
      Value::Int(i) => HashKey::Int(i),
      Value::Float(f) => HashKey::Float(f),
      Value::String(s) => HashKey::String(s),
      _ => return Err(InvalidHashKey(v)),
    })
  }
}
