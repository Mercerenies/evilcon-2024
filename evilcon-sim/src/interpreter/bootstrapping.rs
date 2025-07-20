
use super::class::Class;
use super::eval::EvaluatorState;
use super::value::{Value, HashKey};
use super::error::{EvalError, ControlFlow};
use super::method::{MethodArgs, Method};
use super::operator::{expect_int, expect_string, expect_bool, expect_array, expect_dict};
use crate::ast::identifier::Identifier;

use std::sync::Arc;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct BootstrappedTypes {
  object: Arc<Class>,
  refcounted: Arc<Class>,
  array: Arc<Class>,
  dictionary: Arc<Class>,
  callable: Arc<Class>,
  string: Arc<Class>,
}

impl BootstrappedTypes {
  pub fn bootstrap() -> Self {
    let object = Arc::new(object_class());
    let refcounted = Arc::new(refcounted_class(object.clone()));
    let array = Arc::new(array_class());
    let dictionary = Arc::new(dictionary_class());
    let callable = Arc::new(callable_class());
    let string = Arc::new(string_class());
    Self {
      object,
      refcounted,
      array,
      dictionary,
      callable,
      string,
    }
  }

  pub fn all_global_names(&self) -> Vec<(String, Arc<Class>)> {
    vec![
      ("Object".into(), self.object.clone()),
      ("RefCounted".into(), self.refcounted.clone()),
      ("Array".into(), self.array.clone()),
      ("Dictionary".into(), self.dictionary.clone()),
      ("Callable".into(), self.callable.clone()),
      ("String".into(), self.string.clone()),
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

  pub fn string(&self) -> &Arc<Class> {
    &self.string
  }
}

fn object_class() -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Object")),
    parent: None,
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn refcounted_class(object: Arc<Class>) -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("RefCounted")),
    parent: Some(object),
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn array_class() -> Class {
  let constants = HashMap::new();
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("__getitem__"), Method::rust_method("__getitem__", array_getitem));
  methods.insert(Identifier::from("push_back"), Method::rust_method("push_back", array_push_back));
  methods.insert(Identifier::from("append"), Method::rust_method("append", array_push_back)); // alias of push_back
  methods.insert(Identifier::from("duplicate"), Method::rust_method("duplicate", duplicate_method));
  methods.insert(Identifier::from("resize"), Method::rust_method("resize", array_resize));
  methods.insert(Identifier::from("fill"), Method::rust_method("fill", array_fill));
  methods.insert(Identifier::from("map"), Method::rust_method("map", array_map));
  methods.insert(Identifier::from("filter"), Method::rust_method("map", array_filter));
  methods.insert(Identifier::from("reduce"), Method::rust_method("reduce", array_reduce));
  methods.insert(Identifier::from("slice"), Method::rust_method("slice", array_slice));
  Class {
    name: Some(String::from("Array")),
    parent: None,
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn dictionary_class() -> Class {
  let constants = HashMap::new();
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("__getitem__"), Method::rust_method("__getitem__", dict_getitem));
  methods.insert(Identifier::from("get"), Method::rust_method("get", dict_get));
  methods.insert(Identifier::from("duplicate"), Method::rust_method("duplicate", duplicate_method));
  Class {
    name: Some(String::from("Dictionary")),
    parent: None,
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn callable_class() -> Class {
  let constants = HashMap::new();
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("call"), Method::rust_method("call", call_func));
  Class {
    name: Some(String::from("Callable")),
    parent: None,
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn string_class() -> Class {
  let constants = HashMap::new();
  let mut methods = HashMap::new();
  methods.insert(Identifier::from("substr"), Method::rust_method("substr", string_substr));
  Class {
    name: Some(String::from("String")),
    parent: None,
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

pub fn call_func(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  match state.self_instance() {
    Value::BoundMethod(method) => {
      let globals = method.self_instance.get_class(state.bootstrapped_classes())
        .map(|class| Arc::clone(&class.constants));
      state.call_function(
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
    inst => {
      Err(EvalError::CannotCallValue(inst.to_string()))
    }
  }
}

fn array_getitem(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_array(state.self_instance())?.borrow();
  let index = expect_int(&args.expect_one_arg()?)?;
  if !((0..(self_inst.len() as i64)).contains(&index)) {
    return Err(EvalError::IndexOutOfBounds(index));
  }
  Ok(self_inst[index as usize].clone())
}

fn array_push_back(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let new_value = args.expect_one_arg()?;
  self_inst.push(new_value);
  Ok(Value::Null)
}

fn array_resize(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance())?.borrow_mut();
  let size = expect_int(&args.expect_one_arg()?)?;
  self_inst.resize(size as usize, Value::Null);
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
  let callable = callable.to_rust_function(Arc::clone(state.superglobals()));
  for elem in &mut arr {
    *elem = callable(MethodArgs(vec![elem.clone()]))?;
  }
  Ok(Value::new_array(arr))
}

fn array_filter(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut arr = expect_array(state.self_instance())?.borrow().clone();
  let callable = args.expect_one_arg()?;
  let callable = callable.to_rust_function(Arc::clone(state.superglobals()));
  arr.retain(|elem| callable(MethodArgs(vec![elem.clone()])).unwrap().as_bool());
  Ok(Value::new_array(arr))
}

fn array_reduce(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let arr = expect_array(state.self_instance())?.borrow().clone();
  args.expect_arity_within(1, 2)?;
  let callable = &args.0[0];
  let callable = callable.to_rust_function(Arc::clone(state.superglobals()));
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
