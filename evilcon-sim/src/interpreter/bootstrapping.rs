
use super::class::Class;

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
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Callable")),
    parent: None,
    constants: Rc::new(constants),
    instance_vars: vec![],
    methods,
  }
}
