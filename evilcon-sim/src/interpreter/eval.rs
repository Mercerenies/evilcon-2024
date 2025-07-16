
use super::class::Class;
use super::value::Value;
use super::method::Method;
use crate::ast::identifier::Identifier;

use std::collections::HashMap;
use std::rc::Rc;

#[derive(Debug, Clone)]
pub struct EvaluatorState {
  self_instance: Option<Box<Value>>,
  locals: HashMap<Identifier, Value>,
  globals: Rc<HashMap<Identifier, Value>>,
  superglobal_state: Rc<SuperglobalState>,
}

#[derive(Debug, Clone, Default)]
pub struct SuperglobalState {
  vars: HashMap<Identifier, Value>,
  functions: HashMap<Identifier, Method>,
  loaded_files: HashMap<String, Class>,
}

impl EvaluatorState {
  pub fn new(superglobal_state: Rc<SuperglobalState>) -> Self {
    EvaluatorState {
      self_instance: None,
      locals: HashMap::new(),
      globals: Rc::new(HashMap::new()),
      superglobal_state,
    }
  }

  pub fn with_globals(mut self, globals: Rc<HashMap<Identifier, Value>>) -> Self {
    self.globals = globals;
    self
  }

  pub fn with_self(mut self, self_instance: Option<Box<Value>>) -> Self {
    self.self_instance = self_instance;
    self
  }

  pub fn self_instance(&self) -> Option<&Value> {
    self.self_instance.as_ref().map(|i| i.as_ref())
  }

  pub fn set_local_var(&mut self, ident: Identifier, value: Value) {
    self.locals.insert(ident, value);
  }

  pub fn get_var(&self, ident: &Identifier) -> Option<&Value> {
    self.locals.get(ident)
      .or_else(|| self.globals.get(ident))
      .or_else(|| self.superglobal_state.get_var(ident))
  }

  pub fn get_func(&self, ident: &Identifier) -> Option<&Method> {
    self.superglobal_state.get_func(ident)
  }

  pub fn get_file(&self, path: &str) -> Option<&Class> {
    self.superglobal_state.get_file(path)
  }
}

impl SuperglobalState {
  pub fn new() -> Self {
    Self::default()
  }

  pub fn bind_var(&mut self, ident: Identifier, value: Value) {
    self.vars.insert(ident, value);
  }

  pub fn define_func(&mut self, ident: Identifier, func: Method) {
    self.functions.insert(ident, func);
  }

  pub fn add_file(&mut self, path: String, class: Class) {
    self.loaded_files.insert(path, class);
  }

  pub fn get_var(&self, ident: &Identifier) -> Option<&Value> {
    self.vars.get(ident)
  }

  pub fn get_func(&self, ident: &Identifier) -> Option<&Method> {
    self.functions.get(ident)
  }

  pub fn get_file(&self, path: &str) -> Option<&Class> {
    self.loaded_files.get(path)
  }
}
