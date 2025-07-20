
use super::class::Class;
use super::eval::EvaluatorState;
use super::value::{Value, HashKey};
use super::error::{EvalError, ControlFlow};
use super::method::{MethodArgs, Method};
use super::operator::{expect_int, expect_bool, expect_array, expect_dict};
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
}

impl BootstrappedTypes {
  pub fn bootstrap() -> Self {
    let object = Arc::new(object_class());
    let refcounted = Arc::new(refcounted_class(object.clone()));
    let array = Arc::new(array_class());
    let dictionary = Arc::new(dictionary_class());
    let callable = Arc::new(callable_class());
    Self {
      object,
      refcounted,
      array,
      dictionary,
      callable,
    }
  }

  pub fn all_global_names(&self) -> Vec<(String, Arc<Class>)> {
    vec![
      ("Object".into(), self.object.clone()),
      ("RefCounted".into(), self.refcounted.clone()),
      ("Array".into(), self.array.clone()),
      ("Dictionary".into(), self.dictionary.clone()),
      ("Callable".into(), self.callable.clone()),
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
  methods.insert(Identifier::from("fill"), Method::rust_method("filf", array_fill));
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

fn call_func(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  match state.self_instance() {
    Some(Value::BoundMethod(method)) => {
      let globals = method.self_instance.get_class(state.bootstrapped_classes())
        .map(|class| Arc::clone(&class.constants));
      state.call_function(
        globals,
        &method.method,
        Some(Box::new(method.self_instance.clone())),
        args,
      )
    }
    Some(Value::Lambda(lambda)) => {
      let mut lambda_scope = lambda.outer_scope.clone();
      lambda_scope.bind_arguments(args.0, lambda.contents.params.clone())?;
      let result = lambda_scope.eval_body(&lambda.contents.body);
      ControlFlow::expect_return_or_null(result)
    }
    inst => {
      let inst = inst.cloned().unwrap_or(Value::Null);
      Err(EvalError::CannotCallValue(inst.to_string()))
    }
  }
}

fn array_getitem(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_array(state.self_instance_or_null())?.borrow();
  let index = expect_int(&args.expect_one_arg()?)?;
  if !((0..(self_inst.len() as i64)).contains(&index)) {
    return Err(EvalError::IndexOutOfBounds(index));
  }
  Ok(self_inst[index as usize].clone())
}

fn array_push_back(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance_or_null())?.borrow_mut();
  let new_value = args.expect_one_arg()?;
  self_inst.push(new_value);
  Ok(Value::Null)
}

fn array_resize(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance_or_null())?.borrow_mut();
  let size = expect_int(&args.expect_one_arg()?)?;
  self_inst.resize(size as usize, Value::Null);
  Ok(Value::GLOBAL_OK)
}

fn array_fill(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let mut self_inst = expect_array(state.self_instance_or_null())?.borrow_mut();
  let value = &args.expect_one_arg()?;
  self_inst.fill(value.clone());
  Ok(Value::GLOBAL_OK)
}

fn dict_getitem(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_dict(state.self_instance_or_null())?.borrow();
  let key = HashKey::try_from(&args.expect_one_arg()?)?;
  Ok(self_inst.get(&key).cloned().unwrap_or_default())
}

fn dict_get(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = expect_dict(state.self_instance_or_null())?.borrow();
  args.expect_arity_within(1, 2)?;
  let key = HashKey::try_from(&args.0[0])?;
  let default_value = args.0.get(1).unwrap_or(&Value::Null);
  Ok(self_inst.get(&key).cloned().unwrap_or_else(|| default_value.clone()))
}

fn duplicate_method(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let self_inst = state.self_instance().unwrap_or_default();
  args.expect_arity_within(0, 1)?;
  let arg = args.0.get(0).unwrap_or(&Value::Bool(false));
  let deep = expect_bool(arg)?;
  if deep {
    Ok(self_inst.deep_copy())
  } else {
    Ok(self_inst.shallow_copy())
  }
}
