
use crate::ast::expr::Literal;
use super::class::Class;
use super::method::Method;

use ordered_float::OrderedFloat;
use thiserror::Error;

use std::collections::HashMap;
use std::rc::Rc;
use std::cell::RefCell;
use std::ops::Deref;

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
  class: Rc<Class>,
  dict: HashMap<String, Value>,
}

#[derive(Debug, Clone, Error)]
#[error("Invalid hash key {0:?}")]
pub struct InvalidHashKey(pub Value);

#[derive(Debug, Clone, Error)]
#[error("No such variable {0}")]
pub struct NoSuchVar(pub String);

#[derive(Debug, Clone, Error)]
#[error("No such function {0}")]
pub struct NoSuchFunc(pub String);

impl Value {
  pub fn new_array(values: Vec<Value>) -> Self {
    Value::ArrayRef(Rc::new(RefCell::new(values)))
  }

  pub fn new_dict(values: HashMap<HashKey, Value>) -> Self {
    Value::DictRef(Rc::new(RefCell::new(values)))
  }

  pub fn get_value(&self, name: &str) -> Result<Value, NoSuchVar> {
    // TODO Funcrefs
    if let Value::ObjectRef(obj) = self {
      let obj = obj.borrow();
      obj.dict.get(name).cloned().ok_or(NoSuchVar(name.to_owned()))
    } else {
      Err(NoSuchVar(name.to_owned()))
    }
  }

  pub fn get_func(&self, name: &str) -> Result<Method, NoSuchFunc> {
    let class = self.get_class().ok_or(NoSuchFunc(name.to_owned()))?;
    class.get_func(name).cloned()
  }

  pub fn get_class(&self) -> Option<Rc<Class>> {
    match self {
      Value::ObjectRef(obj) => Some(obj.borrow().class.clone()),
      _ => None,
    }
  }
}

impl Deref for ObjectPtr {
  type Target = Rc<RefCell<ObjectInst>>;

  fn deref(&self) -> &Self::Target {
    &self.value
  }
}

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

impl From<Value> for bool {
  fn from(v: Value) -> Self {
    match v {
      Value::Bool(b) => b,
      Value::Int(i) => i != 0,
      Value::Float(f) => f != 0.0,
      Value::Null => false,
      _ => true,
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
