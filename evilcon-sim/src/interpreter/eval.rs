
use super::class::Class;
use super::class::constant::LazyConst;
use super::value::Value;
use super::method::{Method, MethodArgs};
use super::error::{EvalError, EvalErrorOrControlFlow, ControlFlow, LoopControlFlow};
use crate::ast::identifier::Identifier;
use crate::ast::file::SourceFile;
use crate::ast::expr::Expr;
use crate::ast::stmt::Stmt;

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
      Expr::GetNode(node) => {
        // Okay, this is only used (currently) in LookaheadAiAgent.
        // And its used to evaluate animations (which don't run in
        // this simulation). We have to parse it because it's part of
        // the code, but if we try to eval a GetNode then we've gone
        // down a code path I didn't expect.
        Err(EvalError::UnexpectedGetNode(node.clone().into()))
      }
      Expr::Call { func, args } => {
        let func = match func.as_ref() {
          Expr::Name(id) => self.get_func(id).ok_or_else(|| EvalError::UndefinedFunc(id.clone().into()))?,
          func => { return Err(EvalError::CannotCall(func.clone())); }
        };
        let args = MethodArgs(args.iter().map(|arg| self.eval_expr(arg)).collect::<Result<Vec<_>, _>>()?);
        self.call_function(Some(self.globals.clone()), &func, self.self_instance.as_ref().map(Box::clone), args)
      }
      Expr::Subscript(left, right) => {
        let left = self.eval_expr(left)?;
        let func = left.get_func("__getitem__")?; // Just do it the Python way, even though Godot doesn't :)
        let args = MethodArgs(vec![self.eval_expr(right)?]);
        let globals = left.get_class().map(|class| Rc::clone(&class.constants));
        self.call_function(globals, &func, Some(Box::new(left)), args)
      }
      Expr::Attr(left, name) => {
        let left = self.eval_expr(left)?;
        Ok(left.get_value(name.as_ref())?)
      }
      Expr::AttrCall(left, name, args) => {
        let left = self.eval_expr(left)?;
        let func = left.get_func(name.as_ref())?;
        let args = MethodArgs(args.iter().map(|arg| self.eval_expr(arg)).collect::<Result<Vec<_>, _>>()?);
        let globals = left.get_class().map(|class| Rc::clone(&class.constants));
        self.call_function(globals, &func, Some(Box::new(left)), args)
      }
      Expr::BinaryOp(_left, _op, _right) => {
        todo!()
      }
      Expr::UnaryOp(_op, _right) => {
        todo!()
      }
      Expr::Await(expr) => {
        // Whee, ignore `await` expressions!
        self.eval_expr(expr)
      }
      Expr::Lambda(_lambda) => {
        todo!()
      }
      Expr::Conditional { if_true, cond, if_false } => {
        let cond = self.eval_expr(cond)?;
        if cond.into() {
          self.eval_expr(if_true)
        } else {
          self.eval_expr(if_false)
        }
      }
    }
  }

  pub fn eval_body(&mut self, body: &[Stmt]) -> Result<(), EvalErrorOrControlFlow> {
    for stmt in body {
      self.eval_stmt(stmt)?;
    }
    Ok(())
  }

  pub fn eval_stmt(&mut self, stmt: &Stmt) -> Result<(), EvalErrorOrControlFlow> {
    match stmt {
      Stmt::ExprStmt(expr) => {
        // Evaluate for side effects, then discard
        self.eval_expr(expr)?;
      }
      Stmt::Var(var_stmt) => {
        let initial_value = match var_stmt.initial_value.as_ref() {
          None => Value::default(),
          Some(expr) => self.eval_expr(expr)?,
        };
        self.set_local_var(var_stmt.name.clone(), initial_value);
      }
      Stmt::Return(inner) => {
        let inner = match inner.as_ref() {
          None => Value::default(),
          Some(expr) => self.eval_expr(expr)?,
        };
        return Err(ControlFlow::Return(inner).into());
      }
      Stmt::Pass => {
        // Do nothing :)
      }
      Stmt::Break => {
        return Err(ControlFlow::Break.into());
      }
      Stmt::Continue => {
        return Err(ControlFlow::Continue.into());
      }
      Stmt::If(if_stmt) => {
        if bool::from(self.eval_expr(&if_stmt.condition)?) {
          let mut inner_scope = self.clone();
          inner_scope.eval_body(&if_stmt.body)?;
        } else {
          let mut matched = false;
          for elif_clause in &if_stmt.elif_clauses {
            if bool::from(self.eval_expr(&elif_clause.condition)?) {
              let mut inner_scope = self.clone();
              inner_scope.eval_body(&elif_clause.body)?;
              matched = true;
              break;
            }
          }
          if !matched && let Some(body) = &if_stmt.else_clause {
            self.eval_body(body)?;
          }
        }
      }
      Stmt::While(while_stmt) => {
        while bool::from(self.eval_expr(&while_stmt.condition)?) {
          let mut inner_scope = self.clone();
          let inner_res = inner_scope.eval_body(&while_stmt.body);
          if let Some(cf) = ControlFlow::extract_loop_control(inner_res)? {
            if cf == LoopControlFlow::Break {
              break;
            }
          }
        }
      }
      Stmt::For(for_stmt) => {
        todo!()
      }
      Stmt::AssignOp(left, op, right) => {
        todo!()
      }
    }
    Ok(())
  }

  pub fn call_function(&self,
                       globals: Option<Rc<HashMap<Identifier, LazyConst>>>,
                       method: &Method,
                       self_instance: Option<Box<Value>>,
                       args: MethodArgs) -> Result<Value, EvalError> {
    let mut method_scope = EvaluatorState::new(Rc::clone(&self.superglobal_state)).with_self(self_instance);
    if let Some(globals) = globals {
      method_scope = method_scope.with_globals(globals);
    }
    match method {
      Method::GdMethod(method) => {
        if method.is_static {
          method_scope = method_scope.with_self(None);
        }
        if args.len() != method.params.len() {
          return Err(EvalError::WrongArity { expected: method.params.len(), actual: args.len() });
        }
        for (arg, param) in args.0.into_iter().zip(method.params.clone()) {
          method_scope.set_local_var(param, arg);
        }
        let result = method_scope.eval_body(&method.body);
        ControlFlow::expect_return_or_null(result)
      }
      Method::RustMethod(method) => {
        (method.body)(&mut method_scope, args)
      }
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
