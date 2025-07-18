
use super::class::Class;
use super::eval::EvaluatorState;
use super::value::Value;
use super::error::{EvalError, ControlFlow};
use super::method::{MethodArgs, Method};
use crate::ast::identifier::Identifier;

use std::rc::Rc;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct BootstrappedTypes {
  object: Rc<Class>,
  refcounted: Rc<Class>,
  array: Rc<Class>,
  dictionary: Rc<Class>,
  callable: Rc<Class>,
}

impl BootstrappedTypes {
  pub fn bootstrap() -> Self {
    let object = Rc::new(object_class());
    let refcounted = Rc::new(refcounted_class(object.clone()));
    let array = Rc::new(array_class());
    let dictionary = Rc::new(dictionary_class());
    let callable = Rc::new(callable_class());
    Self {
      object,
      refcounted,
      array,
      dictionary,
      callable,
    }
  }

  pub fn all_global_names(&self) -> Vec<(String, Rc<Class>)> {
    vec![
      ("Object".into(), self.object.clone()),
      ("RefCounted".into(), self.refcounted.clone()),
      ("Array".into(), self.array.clone()),
      ("Dictionary".into(), self.dictionary.clone()),
      ("Callable".into(), self.callable.clone()),
    ]
  }

  pub fn object(&self) -> &Rc<Class> {
    &self.object
  }

  pub fn refcounted(&self) -> &Rc<Class> {
    &self.refcounted
  }

  pub fn array(&self) -> &Rc<Class> {
    &self.array
  }

  pub fn dictionary(&self) -> &Rc<Class> {
    &self.dictionary
  }

  pub fn callable(&self) -> &Rc<Class> {
    &self.callable
  }
}

fn object_class() -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Object")),
    parent: None,
    constants: Rc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn refcounted_class(object: Rc<Class>) -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("RefCounted")),
    parent: Some(object),
    constants: Rc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn array_class() -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Array")),
    parent: None,
    constants: Rc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn dictionary_class() -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Dictionary")),
    parent: None,
    constants: Rc::new(constants),
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
    constants: Rc::new(constants),
    instance_vars: vec![],
    methods,
  }
}

fn call_func(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  match state.self_instance() {
    Some(Value::BoundMethod(method)) => {
      let globals = method.self_instance.get_class(state.bootstrapped_classes())
        .map(|class| Rc::clone(&class.constants));
      state.call_function(
        globals,
        &method.method,
        Some(Box::new(method.self_instance.clone())),
        args,
      )
    }
    Some(Value::Lambda(lambda)) => {
      let mut lambda_scope = lambda.outer_scope.clone();
      if args.len() != lambda.contents.params.len() {
        return Err(EvalError::WrongArity { expected: lambda.contents.params.len(), actual: args.len() });
      }
      for (arg, param) in args.0.into_iter().zip(lambda.contents.params.clone()) {
        lambda_scope.set_local_var(param, arg);
      }
      let result = lambda_scope.eval_body(&lambda.contents.body);
      ControlFlow::expect_return_or_null(result)
    }
    inst => {
      let inst = inst.cloned().unwrap_or(Value::Null);
      Err(EvalError::CannotCallValue(inst))
    }
  }
}
