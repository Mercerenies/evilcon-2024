
use super::class::{Class, ClassBuilder};
use super::eval::{EvaluatorState, GETITEM_METHOD_NAME};
use super::value::{Value, HashKey, CallableWithBindings, EqPtr};
use super::error::{EvalError, ControlFlow};
use super::method::{MethodArgs, Method};
use super::operator::{expect_int, expect_float_loosely, expect_string, expect_bool,
                      expect_array, expect_dict, do_comparison_op};
use crate::ast::identifier::Identifier;
use crate::util::{try_sort_by, try_reduce};

use rand::seq::SliceRandom;

use std::sync::Arc;
use std::collections::HashMap;
use std::cmp::Ordering;

#[derive(Debug, Clone)]
pub struct BootstrappedTypes {
  object: Arc<Class>,
  refcounted: Arc<Class>,
  array: Arc<Class>,
  dictionary: Arc<Class>,
  callable: Arc<Class>,
  int: Arc<Class>,
  string: Arc<Class>,
  signal: Arc<Class>,
}

impl BootstrappedTypes {
  pub fn bootstrap() -> Self {
    let object = Arc::new(object_class());
    let refcounted = Arc::new(refcounted_class(object.clone()));
    let array = Arc::new(array_class());
    let dictionary = Arc::new(dictionary_class());
    let callable = Arc::new(callable_class());
    let int = Arc::new(int_class());
    let string = Arc::new(string_class());
    let signal = Arc::new(signal_class());
    Self {
      object,
      refcounted,
      array,
      dictionary,
      callable,
      int,
      string,
      signal,
    }
  }

  pub fn all_global_names(&self) -> Vec<(String, Arc<Class>)> {
    // Note: We make String and StringName synonyms here. I think
    // that's good enough for this simulation, even though it's not
    // technically true in Godot.
    vec![
      ("Object".into(), self.object.clone()),
      ("RefCounted".into(), self.refcounted.clone()),
      ("Array".into(), self.array.clone()),
      ("Dictionary".into(), self.dictionary.clone()),
      ("Callable".into(), self.callable.clone()),
      ("int".into(), self.int.clone()),
      ("String".into(), self.string.clone()),
      ("StringName".into(), self.string.clone()),
      ("Signal".into(), self.signal.clone()),
    ]
  }

  pub fn object(&self) -> &Arc<Class> {
    &self.object
  }

  pub fn refcounted(&self) -> &Arc<Class> {
    &self.refcounted
  }

  pub fn array(&self) -> &Arc<Class> {
    &self.array
  }

  pub fn dictionary(&self) -> &Arc<Class> {
    &self.dictionary
  }

  pub fn callable(&self) -> &Arc<Class> {
    &self.callable
  }

  pub fn int(&self) -> &Arc<Class> {
    &self.int
  }

  pub fn string(&self) -> &Arc<Class> {
    &self.string
  }

  pub fn signal(&self) -> &Arc<Class> {
    &self.signal
  }
}

fn object_class() -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::new("call"), Method::rust_method("call", call_method_on_obj));
  methods.insert(Identifier::new("callv"), Method::rust_method("callv", callv_method_on_obj));
  methods.insert(Identifier::new("free"), Method::noop());

  ClassBuilder::default()
    .name("Object")
    .methods(methods)
    .build()
}

fn refcounted_class(object: Arc<Class>) -> Class {
  ClassBuilder::default()
    .name("RefCounted")
    .parent(object)
    .build()
}

fn array_class() -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::from(GETITEM_METHOD_NAME), Method::rust_method(GETITEM_METHOD_NAME, array_getitem));
  methods.insert(Identifier::from("clear"), Method::rust_method("clear", array_clear));
  methods.insert(Identifier::from("shuffle"), Method::rust_method("shuffle", array_shuffle));
  methods.insert(Identifier::from("is_empty"), Method::rust_method("is_empty", array_is_empty));
  methods.insert(Identifier::from("remove_at"), Method::rust_method("remove_at", array_remove_at));
  methods.insert(Identifier::from("push_back"), Method::rust_method("push_back", array_push_back));
  methods.insert(Identifier::from("append"), Method::rust_method("append", array_push_back)); // alias of push_back
  methods.insert(Identifier::from("append_array"), Method::rust_method("append_array", array_append_array));
  methods.insert(Identifier::from("duplicate"), Method::rust_method("duplicate", duplicate_method));
  methods.insert(Identifier::from("reverse"), Method::rust_method("reverse", array_reverse));
  methods.insert(Identifier::from("resize"), Method::rust_method("resize", array_resize));
  methods.insert(Identifier::from("fill"), Method::rust_method("fill", array_fill));
  methods.insert(Identifier::from("map"), Method::rust_method("map", array_map));
  methods.insert(Identifier::from("any"), Method::rust_method("any", array_any));
  methods.insert(Identifier::from("all"), Method::rust_method("all", array_all));
  methods.insert(Identifier::from("filter"), Method::rust_method("filter", array_filter));
  methods.insert(Identifier::from("max"), Method::rust_method("max", array_max));
  methods.insert(Identifier::from("min"), Method::rust_method("min", array_min));
  methods.insert(Identifier::from("reduce"), Method::rust_method("reduce", array_reduce));
  methods.insert(Identifier::from("slice"), Method::rust_method("slice", array_slice));
  methods.insert(Identifier::from("sort"), Method::rust_method("sort", array_sort));
  methods.insert(Identifier::from("sort_custom"), Method::rust_method("sort_custom", array_sort_custom));
  ClassBuilder::default()
    .name("Array")
    .methods(methods)
    .build()
}

fn dictionary_class() -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::from(GETITEM_METHOD_NAME), Method::rust_method(GETITEM_METHOD_NAME, dict_getitem));
  methods.insert(Identifier::from("get"), Method::rust_method("get", dict_get));
  methods.insert(Identifier::from("duplicate"), Method::rust_method("duplicate", duplicate_method));
  methods.insert(Identifier::from("keys"), Method::rust_method("keys", dict_keys));
  methods.insert(Identifier::from("values"), Method::rust_method("values", dict_values));
  methods.insert(Identifier::from("merge"), Method::rust_method("merge", dict_merge));
  ClassBuilder::default()
    .name("Dictionary")
    .methods(methods)
    .build()
}

fn callable_class() -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("call"), Method::rust_method("call", call_func));
  methods.insert(Identifier::from("bind"), Method::rust_method("bind", bind_func));
  methods.insert(Identifier::from("bindv"), Method::rust_method("bindv", bindv_func));

  ClassBuilder::default()
    .name("Callable")
    .methods(methods)
    .build()
}

fn int_class() -> Class {
  ClassBuilder::default()
    .name("int")
    .build()
}

fn string_class() -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("substr"), Method::rust_method("substr", string_substr));
  ClassBuilder::default()
    .name("String")
    .methods(methods)
    .build()
}

fn signal_class() -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("emit"), Method::noop());
  methods.insert(Identifier::from("connect"), Method::noop());
  ClassBuilder::default()
    .name("Signal")
    .methods(methods)
    .build()
}

pub fn call_func(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  match state.self_instance() {
    Value::BoundMethod(method) => {
      let globals = method.self_instance.get_class(state.bootstrapped_classes());
      state.call_function_prim(
        globals,
        &method.method,
        Box::new(method.self_instance.clone()),
        args,
      )
    }
    Value::Lambda(lambda) => {
      let mut lambda_scope = lambda.outer_scope.clone();
      lambda_scope.bind_arguments(args.0, lambda.contents.params.clone())?;
      let result = lambda_scope.eval_body(&lambda.contents.body);
      ControlFlow::expect_return_or_null(result)
    }
    Value::CallableWithBindings(inner) => {
      let inner_method = &inner.inner_callable;
      let mut all_args = Vec::new();
      all_args.extend(args.0);
      all_args.extend(inner.bound_params.clone());
      let mut new_state = state.clone().with_self(Box::new(inner_method.clone()));
      call_func(&mut new_state, MethodArgs(all_args))
    }
    inst => {
      Err(EvalError::CannotCallValue(inst.to_string()))
    }
  }
}

fn bindv_func(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let args = args.expect_one_arg()?;
  let args = expect_array(&args)?.borrow().clone();
  Ok(Value::CallableWithBindings(EqPtr::new(CallableWithBindings {
    inner_callable: state.self_instance().clone(),
    bound_params: args,
  })))
}

fn bind_func(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  Ok(Value::CallableWithBindings(EqPtr::new(CallableWithBindings {
    inner_callable: state.self_instance().clone(),
    bound_params: args.0,
  })))
}

fn array_getitem(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_array(state.self_instance())?.borrow();
  let mut index = expect_int(&args.expect_one_arg()?)?;
  if index < 0 {
    index += self_inst.len() as i64;
  }
  if !((0..(self_inst.len() as i64)).contains(&index)) {
    return Err(EvalError::IndexOutOfBounds(index));
  }
  Ok(self_inst[index as usize].clone())
}

fn array_remove_at(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let mut index = expect_int(&args.expect_one_arg()?)?;
  if index < 0 {
    index += self_inst.len() as i64;
  }
  if !((0..(self_inst.len() as i64)).contains(&index)) {
    return Err(EvalError::IndexOutOfBounds(index));
  }
  self_inst.remove(index as usize);
  Ok(Value::Null)
}

fn array_clear(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  args.expect_arity(0)?;
  self_inst.clear();
  Ok(Value::Null)
}

fn array_is_empty(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_array(state.self_instance())?.borrow();
  args.expect_arity(0)?;
  Ok(Value::from(self_inst.is_empty()))
}

fn array_shuffle(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  args.expect_arity(0)?;
  state.do_random(|rng| self_inst.shuffle(rng));
  Ok(Value::Null)
}

fn array_push_back(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let new_value = args.expect_one_arg()?;
  self_inst.push(new_value);
  Ok(Value::Null)
}

// Panics if the two arrays are literally the same array.
fn array_append_array(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let new_values = args.expect_one_arg()?;
  let new_values = expect_array(&new_values)?.borrow();
  self_inst.extend(new_values.iter().cloned());
  Ok(Value::Null)
}

fn array_resize(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let size = expect_int(&args.expect_one_arg()?)?;
  self_inst.resize(size as usize, Value::Null);
  Ok(Value::GLOBAL_OK)
}

fn array_reverse(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  args.expect_arity(0)?;
  self_inst.reverse();
  Ok(Value::GLOBAL_OK)
}

fn array_fill(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let value = &args.expect_one_arg()?;
  self_inst.fill(value.clone());
  Ok(Value::GLOBAL_OK)
}

fn array_map(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow().clone();
  let callable = args.expect_one_arg()?;
  let callable = callable.to_rust_function(&state);
  for elem in &mut arr {
    *elem = callable(MethodArgs(vec![elem.clone()]))?;
  }
  Ok(Value::new_array(arr))
}

fn array_any(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow().clone();
  let callable = args.expect_one_arg()?;
  let callable = callable.to_rust_function(&state);
  for elem in &mut arr {
    if callable(MethodArgs(vec![elem.clone()])).unwrap().as_bool() {
      return Ok(Value::Bool(true));
    }
  }
  Ok(Value::Bool(false))
}

fn array_all(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow().clone();
  let callable = args.expect_one_arg()?;
  let callable = callable.to_rust_function(&state);
  for elem in &mut arr {
    if !callable(MethodArgs(vec![elem.clone()])).unwrap().as_bool() {
      return Ok(Value::Bool(false));
    }
  }
  Ok(Value::Bool(true))
}

fn array_filter(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow().clone();
  let callable = args.expect_one_arg()?;
  let callable = callable.to_rust_function(&state);
  arr.retain(|elem| callable(MethodArgs(vec![elem.clone()])).unwrap().as_bool());
  Ok(Value::new_array(arr))
}

// Just works on numbers for now.
fn array_max(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  fn max(a: Value, b: Value) -> Result<Value, EvalError> {
    let a = expect_float_loosely(&a)?;
    let b = expect_float_loosely(&b)?;
    Ok(Value::from(f64::max(a, b)))
  }

  let arr = expect_array(state.self_instance())?.borrow();
  args.expect_arity(0)?;
  try_reduce(&mut arr.iter().cloned(), max)
    .map(|val| val.unwrap_or_default())
}

// Just works on numbers for now.
fn array_min(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  fn min(a: Value, b: Value) -> Result<Value, EvalError> {
    let a = expect_float_loosely(&a)?;
    let b = expect_float_loosely(&b)?;
    Ok(Value::from(f64::min(a, b)))
  }

  let arr = expect_array(state.self_instance())?.borrow();
  args.expect_arity(0)?;
  try_reduce(&mut arr.iter().cloned(), min)
    .map(|val| val.unwrap_or_default())
}

fn array_reduce(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let arr = expect_array(state.self_instance())?.borrow().clone();
  args.expect_arity_within(1, 2)?;
  let callable = &args.0[0];
  let callable = callable.to_rust_function(&state);
  let mut accum = args.0.get(1).unwrap_or_default().clone();
  let mut iter = arr.into_iter();
  if accum.is_null() {
    accum = iter.next().ok_or_else(|| EvalError::domain_error("Cannot reduce an empty array"))?;
  }
  for elem in iter {
    accum = callable(MethodArgs(vec![accum, elem]))?;
  }
  Ok(accum)
}

fn array_slice(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let arr = expect_array(state.self_instance())?.borrow().clone();
  // Note: I'm explicitly not supporting the `deep` argument. I never
  // use it and it's weird.
  args.expect_arity_within(1, 3)?;
  let begin = {
    let begin = expect_int(&args.0[0])?;
    if begin < 0 { begin + arr.len() as i64 } else { begin }
  };
  let end = {
    let end = args.0.get(1).map(expect_int).transpose()?.unwrap_or(arr.len() as i64);
    if end < 0 { end + arr.len() as i64 } else { end }
  };
  let step = args.0.get(2).map(expect_int).transpose()?.unwrap_or(1);
  if step == 0 {
    return Err(EvalError::domain_error("Step cannot be zero"));
  }

  let arr = if step < 0 {
    (end+1..=begin).rev()
      .step_by((-step) as usize)
      .filter_map(|i| arr.get(i as usize).cloned())
      .collect()
  } else {
    (begin..end)
      .step_by(step as usize)
      .filter_map(|i| arr.get(i as usize).cloned())
      .collect()
  };
  Ok(Value::new_array(arr))
}

fn array_sort(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow_mut();
  args.expect_arity(0)?;
  try_sort_by(&mut arr, do_comparison_op)?;
  Ok(Value::Null)
}

fn array_sort_custom(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow_mut();
  let callable = args.expect_one_arg()?;
  let callable = callable.to_rust_function(&state);
  // NOTE CAREFULLY: This is one of the few places in this codebase
  // where we execute arbitrary user code inside of a
  // RefCell::borrow_mut. A badly written sort comparator function
  // WILL cause Rust to panic, if it tries to borrow the RefCell
  // again.
  try_sort_by(&mut arr, |a, b| {
    Ok::<_, EvalError>(if callable(MethodArgs(vec![a.clone(), b.clone()]))?.as_bool() { Ordering::Less } else { Ordering::Greater })
  })?;
  Ok(Value::Null)
}

fn dict_getitem(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_dict(state.self_instance())?.borrow();
  let key = HashKey::try_from(&args.expect_one_arg()?)?;
  Ok(self_inst.get(&key).cloned().unwrap_or_default())
}

fn dict_get(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_dict(state.self_instance())?.borrow();
  args.expect_arity_within(1, 2)?;
  let key = HashKey::try_from(&args.0[0])?;
  let default_value = args.0.get(1).unwrap_or(&Value::Null);
  Ok(self_inst.get(&key).cloned().unwrap_or_else(|| default_value.clone()))
}

fn dict_keys(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_dict(state.self_instance())?.borrow();
  args.expect_arity(0)?;
  let keys = self_inst.keys().map(|key| Value::from(key.clone())).collect();
  Ok(Value::new_array(keys))
}

fn dict_values(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_dict(state.self_instance())?.borrow();
  args.expect_arity(0)?;
  let values = self_inst.values().cloned().collect();
  Ok(Value::new_array(values))
}

fn dict_merge(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_dict(state.self_instance())?.borrow_mut();
  args.expect_arity_within(1, 2)?;
  let right_hand = expect_dict(&args.0[0])?.borrow(); // Panics if self_inst == right_hand.
  let overwrite = expect_bool(args.0.get(1).unwrap_or(&Value::Bool(false)))?;
  for (key, value) in right_hand.iter() {
    if overwrite || !self_inst.contains_key(key) {
      self_inst.insert(key.clone(), value.clone());
    }
  }
  Ok(Value::Null)
}

fn duplicate_method(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = state.self_instance();
  args.expect_arity_within(0, 1)?;
  let arg = args.0.get(0).unwrap_or(&Value::Bool(false));
  let deep = expect_bool(arg)?;
  if deep {
    Ok(self_inst.deep_copy())
  } else {
    Ok(self_inst.shallow_copy())
  }
}

fn string_substr(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_string(state.self_instance())?;
  args.expect_arity_within(1, 2)?;
  let from = expect_int(&args.0[0])?;
  let to = expect_int(args.0.get(1).unwrap_or(&Value::Int(-1)))?;
  let substr = if to == -1 {
    &self_inst[from as usize..]
  } else {
    &self_inst[from as usize..(to as usize)]
  };
  Ok(Value::String(substr.to_string()))
}

fn call_method_on_obj(state: &mut EvaluatorState, mut args: MethodArgs) -> Result<Value, EvalError> {
  if args.len() < 1 {
    return Err(EvalError::WrongArity { actual: args.len(), expected: 1 });
  }
  let method_name = expect_string(&args.0[0])?.to_owned();
  args.0.remove(0);
  state.call_function_on(state.self_instance(), &method_name, args.0)
}

fn callv_method_on_obj(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let (method_name, args) = args.expect_two_args()?;
  let method_name = expect_string(&method_name)?;
  let args = expect_array(&args)?.borrow().clone();
  state.call_function_on(state.self_instance(), &method_name, args)
}
