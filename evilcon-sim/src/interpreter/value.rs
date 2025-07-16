
use crate::ast::expr::Literal;
use crate::ast::identifier::Identifier;
use super::class::Class;
use super::method::Method;
use super::error::EvalError;

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

#[derive(Debug, Clone)]
pub enum AssignmentLeftHand {
  Name(Identifier),
  Subscript(Value, Value),
  Attr(Value, Identifier),
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

/// Thin wrapper around `Box<dyn Iterator>`, used for [`Value`].
pub struct ValueIter {
  inner: Box<dyn Iterator<Item = Value> + 'static>,
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
  pub fn float(f: impl Into<OrderedFloat<f64>>) -> Self {
    Value::Float(f.into())
  }

  pub fn new_array(values: Vec<Value>) -> Self {
    Value::ArrayRef(Rc::new(RefCell::new(values)))
  }

  pub fn new_dict(values: HashMap<HashKey, Value>) -> Self {
    Value::DictRef(Rc::new(RefCell::new(values)))
  }

  pub fn as_bool(&self) -> bool {
    match self {
      Value::Bool(b) => *b,
      Value::Int(i) => *i != 0,
      Value::Float(f) => *f != 0.0,
      Value::Null => false,
      _ => true,
    }
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

  pub fn set_value(&self, name: &str, value: Value) -> Result<(), EvalError> {
    if let Value::ObjectRef(obj) = self {
      let mut obj = obj.borrow_mut();
      obj.dict.insert(name.to_owned(), value);
      Ok(())
    } else {
      Err(EvalError::type_error("object", self.clone()))
    }
  }

  pub fn set_index(&self, index: Value, value: Value) -> Result<(), EvalError> {
    match self {
      Value::ArrayRef(arr) => {
        let mut arr = arr.borrow_mut();
        if let Value::Int(index) = index {
          if (0..arr.len() as i64).contains(&index) {
            arr[index as usize] = value;
            Ok(())
          } else {
            Err(EvalError::IndexOutOfBounds(index as usize))
          }
        } else {
          Err(EvalError::type_error("integer", value))
        }
      }
      Value::DictRef(d) => {
        let mut d = d.borrow_mut();
        let key = HashKey::try_from(index)?;
        d.insert(key, value);
        Ok(())
      }
      _ => Err(EvalError::type_error("array or dictionary", self.clone())),
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

  pub fn try_iter(&self) -> Result<ValueIter, EvalError> {
    // Currently we only support arrays and dictionaries.
    match self {
      Value::ArrayRef(arr) => {
        let elems = arr.borrow().clone();
        Ok(ValueIter { inner: Box::new(elems.into_iter()) })
      }
      Value::DictRef(d) => {
        let entries = d.borrow().clone();
        Ok(ValueIter { inner: Box::new(entries.into_keys().map(Value::from)) })
      }
      _ => {
        Err(EvalError::CannotIterate(self.clone()))
      }
    }
  }
}

impl Iterator for ValueIter {
  type Item = Value;

  fn next(&mut self) -> Option<Self::Item> {
    self.inner.next()
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
