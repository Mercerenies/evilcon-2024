
use super::class::Class;
use super::class::constant::LazyConst;
use super::value::Value;
use super::method::Method;
use super::error::EvalError;
use crate::ast::identifier::Identifier;
use crate::ast::file::SourceFile;
use crate::ast::expr::Expr;

use std::collections::HashMap;
use std::rc::Rc;

#[derive(Debug, Clone)]
pub struct EvaluatorState {
  self_instance: Option<Box<Value>>,
  locals: HashMap<Identifier, Value>,
  globals: Rc<HashMap<Identifier, LazyConst>>,
  superglobal_state: Rc<SuperglobalState>,
}

#[derive(Debug, Clone, Default)]
pub struct SuperglobalState {
  vars: HashMap<Identifier, Value>,
  functions: HashMap<Identifier, Method>,
  loaded_files: HashMap<String, Rc<Class>>,
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

  pub fn with_globals(mut self, globals: Rc<HashMap<Identifier, LazyConst>>) -> Self {
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

  pub fn get_var(&self, ident: &Identifier) -> Result<Option<&Value>, EvalError> {
    if let Some(local) = self.locals.get(ident) {
      return Ok(Some(local));
    }
    if let Some(glob) = self.get_global(ident)? {
      return Ok(Some(glob));
    }
    Ok(self.superglobal_state.get_var(ident))
  }

  fn get_global(&self, ident: &Identifier) -> Result<Option<&Value>, EvalError> {
    let Some(glob) = self.globals.get(ident) else {
      return Ok(None);
    };
    glob.get(self).map(Some)
  }

  pub fn get_func(&self, ident: &Identifier) -> Option<Method> {
    if let Some(self_instance) = &self.self_instance {
      if let Ok(func) = self_instance.get_func(ident.as_ref()) {
        return Some(func);
      }
    }
    self.get_superglobal_func(ident).cloned()
  }

  pub fn get_superglobal_func(&self, ident: &Identifier) -> Option<&Method> {
    self.superglobal_state.get_func(ident)
  }

  pub fn get_file(&self, path: &str) -> Option<Rc<Class>> {
    self.superglobal_state.get_file(path)
  }

  pub fn eval_expr(&self, expr: &Expr) -> Result<Value, EvalError> {
    match expr {
      Expr::Array(args) => {
        let args = args.iter().map(|arg| self.eval_expr(arg)).collect::<Result<Vec<_>, _>>()?;
        Ok(Value::new_array(args))
      }
      Expr::Dictionary(pairs) => {
        let entries = pairs.iter()
          .map(|entry| Ok((self.eval_expr(&entry.key)?.try_into()?, self.eval_expr(&entry.value)?)))
          .collect::<Result<HashMap<_, _>, EvalError>>()?;
        Ok(Value::new_dict(entries))
      }
      Expr::Literal(lit) => {
        Ok(lit.clone().into())
      }
      Expr::Name(name) => {
        let value = self.get_var(name)?;
        if let Some(value) = value {
          return Ok(value.clone());
        }
        // Try to look up on `self`.
        if let Some(obj) = self.self_instance() && let Ok(value) = obj.get_value(name.as_ref()) {
          return Ok(value.clone());
        }
        Err(EvalError::UndefinedVariable(name.clone().into()))
      }
      _ => todo!(),
    }
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
    self.loaded_files.insert(path, Rc::new(class));
  }

  pub fn load_file(&mut self, path: String, source_file: SourceFile) -> Result<(), EvalError> {
    let class = Class::load_from_file(self, source_file)?;
    self.loaded_files.insert(path, Rc::new(class));
    Ok(())
  }

  pub fn get_var(&self, ident: &Identifier) -> Option<&Value> {
    self.vars.get(ident)
  }

  pub fn get_func(&self, ident: &Identifier) -> Option<&Method> {
    self.functions.get(ident)
  }

  pub fn get_file(&self, path: &str) -> Option<Rc<Class>> {
    self.loaded_files.get(path).cloned()
  }
}
