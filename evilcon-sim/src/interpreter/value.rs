
use crate::ast::expr::{Literal, Lambda};
use crate::ast::identifier::Identifier;
use crate::ast::pattern::Pattern;
use super::class::Class;
use super::method::{Method, MethodArgs};
use super::error::EvalError;
use super::bootstrapping::{self, BootstrappedTypes};
use super::eval::{EvaluatorState, SuperglobalState, GETITEM_METHOD_NAME};

use ordered_float::OrderedFloat;
use thiserror::Error;
use ordermap::OrderMap;
use rand::RngCore;

use std::collections::HashMap;
use std::sync::Arc;
use std::cell::RefCell;
use std::ops::Deref;
use std::fmt::{self, Display, Debug, Formatter};
use std::hash::Hash;
use std::borrow::Borrow;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub enum Value {
  #[default]
  Null,
  Bool(bool),
  Int(i64),
  Float(OrderedFloat<f64>),
  String(String),
  ArrayRef(Arc<RefCell<Vec<Value>>>),
  DictRef(Arc<RefCell<OrderMap<HashKey, Value>>>),
  ClassRef(Arc<Class>),
  ObjectRef(EqPtrMut<ObjectInst>),
  BoundMethod(EqPtr<BoundMethod>),
  Lambda(EqPtr<LambdaValue>),
  CallableWithBindings(EqPtr<CallableWithBindings>),
  EnumType(OrderMap<Identifier, i64>),
  /// Stub for signal values. We do the absolute minimum amount of
  /// mocking necessary to make this exist in the system.
  SignalStub,
}

#[derive(Debug, Clone)]
pub enum AssignmentLeftHand {
  Name(Identifier),
  Subscript(Value, Value),
  Attr(Value, Identifier),
}

#[derive(Clone)]
pub struct LambdaValue {
  pub contents: Arc<Lambda>,
  pub outer_scope: EvaluatorState,
}

#[derive(Debug, Clone)]
pub struct CallableWithBindings {
  pub inner_callable: Value,
  pub bound_params: Vec<Value>,
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
#[error("Not a simple value {0:?}")]
pub struct InvalidSimpleValue(pub String);

#[derive(Debug, Clone, Error)]
#[error("No such variable {0}")]
pub struct NoSuchVar(pub String);

#[derive(Debug, Clone, Error)]
#[error("No such function {0}")]
pub struct NoSuchFunc(pub String);

impl Value {
  pub const GLOBAL_OK: Value = Value::Int(0);

  pub fn is_null(&self) -> bool {
    matches!(self, Value::Null)
  }

  pub fn float(f: impl Into<OrderedFloat<f64>>) -> Self {
    Value::Float(f.into())
  }

  pub fn new_array(values: Vec<Value>) -> Self {
    Value::ArrayRef(Arc::new(RefCell::new(values)))
  }

  pub fn new_dict(values: OrderMap<HashKey, Value>) -> Self {
    Value::DictRef(Arc::new(RefCell::new(values)))
  }

  pub fn new_object(class: Arc<Class>) -> Self {
    Value::ObjectRef(EqPtrMut::new(ObjectInst { class, dict: HashMap::new() }))
  }

  pub fn matches(&self, pattern: &Pattern) -> bool {
    match pattern {
      Pattern::Underscore => {
        // Wildcard; always matches
        true
      }
      Pattern::Literal(lit) => {
        let pattern_value = Value::from(lit.clone());
        pattern_value == *self
      }
    }
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
    if let Some(class) = self.get_class(superglobals.bootstrapped_classes()) &&
      let Some(proxy_var) = class.get_proxy_var(name) {
        return proxy_var.get_field(superglobals, self);
    }
    self.get_value_raw(name, superglobals)
  }

  pub fn get_value_raw(&self, name: &str, superglobals: &Arc<SuperglobalState>) -> Result<Value, EvalError> {
    struct ShouldNotUseRandom;
    impl RngCore for ShouldNotUseRandom {
      fn next_u32(&mut self) -> u32 {
        panic!("RNG should not be used in const context")
      }
      fn next_u64(&mut self) -> u64 {
        panic!("RNG should not be used in const context")
      }
      fn fill_bytes(&mut self, _dest: &mut [u8]) {
        panic!("RNG should not be used in const context")
      }
    }

    if let Value::EnumType(dict) = self {
      return dict.get(name).map(|i| Value::from(*i)).ok_or(NoSuchVar(name.to_owned()).into());
    } else if let Value::ClassRef(cls) = self && let Some(constant) = cls.get_constant(name) {
      // Hoping the constants are *really* simple and never use RNG.
      // If I'm wrong, I want to know.
      let const_context = EvaluatorState::new(Arc::clone(superglobals), ShouldNotUseRandom)
        .with_enclosing_class(Some(cls.clone()));
      return constant.get(&const_context).cloned();
    } else if let Value::ObjectRef(obj) = self {
      let obj = RefCell::borrow(&obj);
      if let Some(simple_name) = obj.dict.get(name).cloned() {
        return Ok(simple_name);
      }
    }
    if let Ok(func) = self.get_func(name, superglobals.bootstrapped_classes()) {
      Ok(Value::BoundMethod(EqPtr::new(BoundMethod::new(self.clone(), func))))
    } else {
      Err(NoSuchVar(name.to_owned()).into())
    }
  }

  pub fn set_value(&self, name: &str, value: Value, superglobals: &Arc<SuperglobalState>) -> Result<(), EvalError> {
    if let Some(class) = self.get_class(superglobals.bootstrapped_classes()) &&
      let Some(proxy_var) = class.get_proxy_var(name) {
        return proxy_var.set_field(superglobals, self, value);
    }
    self.set_value_raw(name, value)
  }

  pub fn set_value_raw(&self, name: &str, value: Value) -> Result<(), EvalError> {
    if let Value::ObjectRef(obj) = self {
      let mut obj = obj.borrow_mut();
      obj.dict.insert(name.to_owned(), value);
      Ok(())
    } else {
      Err(EvalError::type_error("object", self.clone()))
    }
  }

  pub fn get_index(&self, index: Value, state: &EvaluatorState) -> Result<Value, EvalError> {
    state.call_function_on(self, GETITEM_METHOD_NAME, vec![index])
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

  /// If `self` is a class, returns `self`. Otherwise, returns the
  /// class of `self`, if it exists.
  pub fn get_call_target(&self, bootstrapping: &BootstrappedTypes) -> Option<Arc<Class>> {
    if let Value::ClassRef(class) = self {
      Some(Arc::clone(class))
    } else {
      self.get_class(bootstrapping)
    }
  }

  pub fn get_class(&self, bootstrapping: &BootstrappedTypes) -> Option<Arc<Class>> {
    match self {
      Value::Int(_) => Some(Arc::clone(bootstrapping.int())),
      Value::ObjectRef(obj) => Some(RefCell::borrow(&obj).class.clone()),
      Value::String(_) => Some(Arc::clone(bootstrapping.string())),
      Value::ArrayRef(_) => Some(Arc::clone(bootstrapping.array())),
      Value::DictRef(_) => Some(Arc::clone(bootstrapping.dictionary())),
      Value::BoundMethod(_) | Value::Lambda(_) | Value::CallableWithBindings(_) =>
        Some(Arc::clone(bootstrapping.callable())),
      Value::SignalStub => Some(Arc::clone(bootstrapping.signal())),
      _ => None,
    }
  }

  pub fn try_iter(&self) -> Result<ValueIter, EvalError> {
    // Currently we only support arrays and dictionaries.
    match self {
      Value::ArrayRef(arr) => {
        let elems = RefCell::borrow(&arr).clone();
        Ok(ValueIter { inner: Box::new(elems.into_iter()) })
      }
      Value::DictRef(d) => {
        let entries = RefCell::borrow(&d).clone();
        Ok(ValueIter { inner: Box::new(entries.into_keys().map(Value::from)) })
      }
      _ => {
        Err(EvalError::CannotIterate(self.to_string()))
      }
    }
  }

  pub fn shallow_copy(&self) -> Value {
    match self {
      Value::Null | Value::Bool(_) | Value::Int(_) | Value::Float(_) | Value::String(_) |
        Value::ClassRef(_) | Value::BoundMethod(_) | Value::Lambda(_) | Value::EnumType(_) |
        Value::SignalStub | Value::CallableWithBindings(_) => self.clone(),
      Value::ObjectRef(_) => {
        tracing::warn!("Shallow copy of object has no effect");
        self.clone()
      }
      Value::ArrayRef(arr) => {
        Value::new_array(RefCell::borrow(arr).clone())
      }
      Value::DictRef(d) => {
        Value::new_dict(RefCell::borrow(d).clone())
      }
    }
  }

  /// Deep-copy recursively on arrays and dictionaries.
  pub fn deep_copy(&self) -> Value {
    match self {
      Value::Null | Value::Bool(_) | Value::Int(_) | Value::Float(_) | Value::String(_) |
        Value::ClassRef(_) | Value::BoundMethod(_) | Value::Lambda(_) | Value::EnumType(_) |
        Value::ObjectRef(_) | Value::SignalStub | Value::CallableWithBindings(_) => self.clone(),
      Value::ArrayRef(arr) => {
        let new_arr = RefCell::borrow(arr).iter().map(|v| v.deep_copy()).collect();
        Value::new_array(new_arr)
      }
      Value::DictRef(d) => {
        let new_dict = RefCell::borrow(d).iter().map(|(k, v)| {
          let k = Value::from(k.clone()).deep_copy().try_into().expect("Duplicating a hash key should produce a hash key");
          let v = v.deep_copy();
          (k, v)
        }).collect();
        Value::new_dict(new_dict)
      }
    }
  }

  pub fn to_rust_function(&self, state: &EvaluatorState) -> impl Fn(MethodArgs) -> Result<Value, EvalError> {
    move |args| {
      let mut state = state.clone().with_self(Box::new(self.clone()));
      bootstrapping::call_func(&mut state, args)
    }
  }
}

impl ObjectInst {
  pub fn dict_get<K>(&self, key: &K) -> Option<&Value>
  where K: Eq + Hash + ?Sized,
        String: Borrow<K> {
    self.dict.get(key)
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

impl Default for &Value {
  fn default() -> Self {
    &Value::Null
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

impl From<f64> for Value {
  fn from(f: f64) -> Self {
    Value::Float(f.into())
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

impl From<bool> for Value {
  fn from(b: bool) -> Self {
    Value::Bool(b)
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

impl TryFrom<&Value> for HashKey {
  type Error = InvalidHashKey;

  fn try_from(v: &Value) -> Result<Self, Self::Error> {
    Ok(match v {
      Value::Null => HashKey::Null,
      Value::Bool(b) => HashKey::Bool(*b),
      Value::Int(i) => HashKey::Int(*i),
      Value::Float(f) => HashKey::Float(*f),
      Value::String(s) => HashKey::String(s.to_owned()),
      _ => return Err(InvalidHashKey(v.to_string())),
    })
  }
}

impl TryFrom<Value> for HashKey {
  type Error = InvalidHashKey;

  fn try_from(v: Value) -> Result<Self, Self::Error> {
    Self::try_from(&v)
  }
}

impl From<SimpleValue> for Value {
  fn from(s: SimpleValue) -> Self {
    match s {
      SimpleValue::Null => Value::Null,
      SimpleValue::Bool(b) => Value::Bool(b),
      SimpleValue::Int(i) => Value::Int(i),
      SimpleValue::Float(f) => Value::Float(f),
      SimpleValue::String(s) => Value::String(s),
      SimpleValue::ClassRef(c) => Value::ClassRef(c),
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
      _ => return Err(InvalidSimpleValue(v.to_string())),
    })
  }
}

impl From<f64> for SimpleValue {
  fn from(f: f64) -> Self {
    SimpleValue::Float(OrderedFloat(f))
  }
}

impl Display for Value {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    fn pretty_write_object(f: &mut Formatter, object: &ObjectInst) -> fmt::Result {
      let cls = &object.class;
      write!(f, "{}", cls.instance_to_string(object))
    }

    match self {
      Value::Null => write!(f, "null"),
      Value::Bool(b) => write!(f, "{}", b),
      Value::Int(i) => write!(f, "{}", i),
      Value::Float(d) => write!(f, "{}", d),
      Value::String(s) => write!(f, "\"{}\"", s),
      Value::ArrayRef(arr) => write!(f, "[{}]", RefCell::borrow(arr).iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", ")),
      Value::DictRef(d) => write!(f, "{{{}}}", RefCell::borrow(d).iter().map(|(k, v)| format!("{}: {}", k, v)).collect::<Vec<_>>().join(", ")),
      Value::ClassRef(cls) => write!(f, "<class {}>", cls.name().unwrap_or("<anon>")),
      Value::ObjectRef(obj) => pretty_write_object(f, &RefCell::borrow(obj)),
      Value::BoundMethod(_) => write!(f, "<method>"),
      Value::Lambda(_) => write!(f, "<lambda>"),
      Value::CallableWithBindings(_) => write!(f, "<callable>"),
      Value::EnumType(_) => write!(f, "<enum>"),
      Value::SignalStub => write!(f, "<signal>"),
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

impl Debug for LambdaValue {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    f.debug_struct("LambdaValue")
      .field("contents", &self.contents)
      .field("outer_scope", &"<state>")
      .finish()
  }
}
