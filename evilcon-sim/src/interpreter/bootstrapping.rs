
use super::class::Class;
use super::eval::EvaluatorState;
use super::value::{Value, HashKey};
use super::error::{EvalError, ControlFlow};
use super::method::{MethodArgs, Method};
use super::operator::expect_int;
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
  methods.insert(Identifier::from("__getitem__"), Method::rust_method("get", array_getitem));
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
  methods.insert(Identifier::from("__getitem__"), Method::rust_method("get", dict_getitem));
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
  let Some(Value::ArrayRef(self_inst)) = state.self_instance() else {
    let self_inst = state.self_instance().cloned().unwrap_or_default();
    return Err(EvalError::type_error("array", self_inst));
  };
  let self_inst = self_inst.borrow_mut();
  args.expect_arity(1)?;
  let [index] = args.0.try_into().unwrap();
  let index = expect_int(&index)?;
  if !((0..(self_inst.len() as i64)).contains(&index)) {
    return Err(EvalError::IndexOutOfBounds(index));
  }
  Ok(self_inst[index as usize].clone())
}

fn dict_getitem(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let Some(Value::DictRef(self_inst)) = state.self_instance() else {
    let self_inst = state.self_instance().cloned().unwrap_or_default();
    return Err(EvalError::type_error("dictionary", self_inst));
  };
  let self_inst = self_inst.borrow_mut();
  args.expect_arity(1)?;
  let [key] = args.0.try_into().unwrap();
  let key = HashKey::try_from(key)?;
  Ok(self_inst.get(&key).cloned().unwrap_or_default())
}
