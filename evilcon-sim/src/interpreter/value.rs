
use crate::ast::expr::{Literal, Lambda};
use crate::ast::identifier::Identifier;
use super::class::Class;
use super::method::Method;
use super::error::EvalError;
use super::bootstrapping::BootstrappedTypes;
use super::eval::{EvaluatorState, SuperglobalState};

use ordered_float::OrderedFloat;
use thiserror::Error;

use std::collections::HashMap;
use std::sync::Arc;
use std::cell::RefCell;
use std::ops::Deref;
use std::fmt::{Display, Formatter};

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub enum Value {
  #[default]
  Null,
  Bool(bool),
  Int(i64),
  Float(OrderedFloat<f64>),
  String(String),
  ArrayRef(Arc<RefCell<Vec<Value>>>),
  DictRef(Arc<RefCell<HashMap<HashKey, Value>>>),
  ClassRef(Arc<Class>),
  ObjectRef(EqPtrMut<ObjectInst>),
  BoundMethod(EqPtr<BoundMethod>),
  Lambda(EqPtr<LambdaValue>),
  EnumType(HashMap<Identifier, i64>),
}

#[derive(Debug, Clone)]
pub enum AssignmentLeftHand {
  Name(Identifier),
  Subscript(Value, Value),
  Attr(Value, Identifier),
}

#[derive(Debug, Clone)]
pub struct LambdaValue {
  pub contents: Arc<Lambda>,
  pub outer_scope: EvaluatorState,
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

#[derive(Debug)]
pub struct EqPtrMut<T> {
  pub value: Arc<RefCell<T>>,
}

#[derive(Debug)]
pub struct EqPtr<T> {
  pub value: Arc<T>,
}

#[derive(Debug, Clone)]
pub struct ObjectInst {
  class: Arc<Class>,
  dict: HashMap<String, Value>,
}

#[derive(Debug, Clone)]
pub struct BoundMethod {
  pub self_instance: Value,
  pub method: Method,
}

/// Thin wrapper around `Box<dyn Iterator>`, used for [`Value`].
pub struct ValueIter {
  inner: Box<dyn Iterator<Item = Value> + 'static>,
}

#[derive(Debug, Clone, Error)]
#[error("Invalid hash key {0:?}")]
pub struct InvalidHashKey(pub String);

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
    Value::ArrayRef(Arc::new(RefCell::new(values)))
  }

  pub fn new_dict(values: HashMap<HashKey, Value>) -> Self {
    Value::DictRef(Arc::new(RefCell::new(values)))
  }

  pub fn new_object(class: Arc<Class>) -> Self {
    Value::ObjectRef(EqPtrMut::new(ObjectInst { class, dict: HashMap::new() }))
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

  pub fn get_value(&self, name: &str, superglobals: &Arc<SuperglobalState>) -> Result<Value, EvalError> {
    if let Value::EnumType(dict) = self {
      dict.get(name).map(|i| Value::from(*i)).ok_or(NoSuchVar(name.to_owned()).into())
    } else if let Value::ClassRef(cls) = self && let Some(constant) = cls.constants.get(name) {
      let const_context = EvaluatorState::new(Arc::clone(superglobals))
        .with_globals(Arc::clone(&cls.constants));
      constant.get(&const_context).cloned()
    } else if let Value::ObjectRef(obj) = self {
      let obj = obj.borrow();
      obj.dict.get(name).cloned().ok_or(NoSuchVar(name.to_owned()).into())
    } else if let Ok(func) = self.get_func(name, superglobals.bootstrapped_classes()) {
      Ok(Value::BoundMethod(EqPtr::new(BoundMethod::new(self.clone(), func))))
    } else {
      Err(NoSuchVar(name.to_owned()).into())
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
            Err(EvalError::IndexOutOfBounds(index))
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

  pub fn get_func(&self, name: &str, bootstrapping: &BootstrappedTypes) -> Result<Method, NoSuchFunc> {
    if let Value::ClassRef(cls) = self && let Ok(method) = cls.get_func(name) && method.is_static() {
      return Ok(method.clone());
    }
    if let Value::ClassRef(_) = self && name == "new" {
      return Ok(Method::constructor_method());
    }
    let class = self.get_class(bootstrapping).ok_or(NoSuchFunc(name.to_owned()))?;
    class.get_func(name).cloned()
  }

  pub fn get_class(&self, bootstrapping: &BootstrappedTypes) -> Option<Arc<Class>> {
    match self {
      Value::ObjectRef(obj) => Some(obj.borrow().class.clone()),
      Value::ArrayRef(_) => Some(Arc::clone(bootstrapping.array())),
      Value::DictRef(_) => Some(Arc::clone(bootstrapping.dictionary())),
      Value::BoundMethod(_) | Value::Lambda(_) => Some(Arc::clone(bootstrapping.callable())),
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
        Err(EvalError::CannotIterate(self.to_string()))
      }
    }
  }
}

impl BoundMethod {
  pub fn new(self_instance: Value, method: Method) -> Self {
    BoundMethod { self_instance, method }
  }
}

impl<T> EqPtrMut<T> {
  pub fn new(value: T) -> Self {
    EqPtrMut {
      value: Arc::new(RefCell::new(value)),
    }
  }
}

impl<T> EqPtr<T> {
  pub fn new(value: T) -> Self {
    EqPtr {
      value: Arc::new(value),
    }
  }
}

impl<T> Clone for EqPtr<T> {
  fn clone(&self) -> Self {
    EqPtr {
      value: Arc::clone(&self.value),
    }
  }
}

impl<T> Clone for EqPtrMut<T> {
  fn clone(&self) -> Self {
    EqPtrMut {
      value: Arc::clone(&self.value),
    }
  }
}

impl Iterator for ValueIter {
  type Item = Value;

  fn next(&mut self) -> Option<Self::Item> {
    self.inner.next()
  }
}

impl<T> Deref for EqPtrMut<T> {
  type Target = Arc<RefCell<T>>;

  fn deref(&self) -> &Self::Target {
    &self.value
  }
}

impl<T> Deref for EqPtr<T> {
  type Target = Arc<T>;

  fn deref(&self) -> &Self::Target {
    &self.value
  }
}

impl<T> PartialEq for EqPtr<T> {
  fn eq(&self, other: &Self) -> bool {
    Arc::ptr_eq(&self.value, &other.value)
  }
}

impl<T> Eq for EqPtr<T> {}

impl<T> PartialEq for EqPtrMut<T> {
  fn eq(&self, other: &Self) -> bool {
    Arc::ptr_eq(&self.value, &other.value)
  }
}

impl<T> Eq for EqPtrMut<T> {}

impl From<i64> for Value {
  fn from(i: i64) -> Self {
    Value::Int(i)
  }
}

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

impl From<String> for Value {
  fn from(s: String) -> Self {
    Value::String(s)
  }
}

impl<'a> From<&'a str> for Value {
  fn from(s: &'a str) -> Self {
    Value::String(s.into())
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
      _ => return Err(InvalidHashKey(v.to_string())),
    })
  }
}

impl Display for Value {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      Value::Null => write!(f, "null"),
      Value::Bool(b) => write!(f, "{}", b),
      Value::Int(i) => write!(f, "{}", i),
      Value::Float(d) => write!(f, "{}", d),
      Value::String(s) => write!(f, "\"{}\"", s),
      Value::ArrayRef(arr) => write!(f, "[{}]", arr.borrow().iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", ")),
      Value::DictRef(d) => write!(f, "{{{}}}", d.borrow().iter().map(|(k, v)| format!("{}: {}", k, v)).collect::<Vec<_>>().join(", ")),
      Value::ClassRef(cls) => write!(f, "<class {}>", cls.name.as_ref().map(|x| &**x).unwrap_or("<anon>")),
      Value::ObjectRef(_) => write!(f, "<object>"),
      Value::BoundMethod(_) => write!(f, "<method>"),
      Value::Lambda(_) => write!(f, "<lambda>"),
      Value::EnumType(_) => write!(f, "<enum>"),
    }
  }
}

impl Display for HashKey {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      HashKey::Null => write!(f, "null"),
      HashKey::Bool(b) => write!(f, "{}", b),
      HashKey::Int(i) => write!(f, "{}", i),
      HashKey::Float(d) => write!(f, "{}", d),
      HashKey::String(s) => write!(f, "\"{}\"", s),
    }
  }
}
