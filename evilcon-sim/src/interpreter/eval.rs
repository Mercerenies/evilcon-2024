
use super::class::{Class, ClassBuilder};
use super::value::{Value, AssignmentLeftHand, EqPtr, LambdaValue, SimpleValue};
use super::method::{Method, MethodArgs};
use super::error::{EvalError, EvalErrorOrControlFlow, ControlFlow, LoopControlFlow, ExpectedArity};
use super::operator::{eval_unary_op, eval_binary_op};
use super::bootstrapping::BootstrappedTypes;
use crate::ast::identifier::{Identifier, ResourcePath};
use crate::ast::file::SourceFile;
use crate::ast::expr::Expr;
use crate::ast::expr::operator::{BinaryOp, AssignOp};
use crate::ast::decl::Parameter;
use crate::ast::stmt::Stmt;

use ordermap::OrderMap;
use rand::RngCore;

use std::hash::Hash;
use std::collections::HashMap;
use std::sync::Arc;
use std::borrow::Borrow;
use std::cell::RefCell;

pub const GETITEM_METHOD_NAME: &str = "__getitem__";

#[derive(Clone)]
pub struct EvaluatorState {
  self_instance: Box<Value>,
  locals: HashMap<Identifier, Value>,
  enclosing_class: Option<Arc<Class>>,
  superglobal_state: Arc<SuperglobalState>,
  // I am going straight to hell for writing this in a ref cell. Oh
  // well, the consequences of my design choices.
  random_generator: Arc<RefCell<dyn RngCore>>,
}

#[derive(Debug, Clone)]
pub struct SuperglobalState {
  vars: HashMap<Identifier, SimpleValue>,
  functions: HashMap<Identifier, Method>,
  loaded_files: HashMap<ResourcePath, Arc<Class>>,
  bootstrapped_classes: BootstrappedTypes,
}

impl EvaluatorState {
  pub fn new(superglobal_state: Arc<SuperglobalState>, random_generator: impl RngCore + 'static) -> Self {
    EvaluatorState {
      self_instance: Box::new(Value::default()),
      locals: HashMap::new(),
      enclosing_class: None,
      superglobal_state,
      random_generator: Arc::new(RefCell::new(random_generator)),
    }
  }

  pub fn bootstrapped_classes(&self) -> &BootstrappedTypes {
    &self.superglobal_state.bootstrapped_classes
  }

  pub fn superglobals(&self) -> &Arc<SuperglobalState> {
    &self.superglobal_state
  }

  pub fn with_enclosing_class(mut self, enclosing_class: Option<Arc<Class>>) -> Self {
    self.enclosing_class = enclosing_class;
    self
  }

  pub fn with_self(mut self, self_instance: Box<Value>) -> Self {
    self.self_instance = self_instance;
    self
  }

  pub fn self_instance(&self) -> &Value {
    &self.self_instance
  }

  pub fn superglobal_state(&self) -> &Arc<SuperglobalState> {
    &self.superglobal_state
  }

  pub fn has_local_var(&self, ident: &Identifier) -> bool {
    self.locals.contains_key(ident)
  }

  pub fn set_local_var(&mut self, ident: Identifier, value: Value) {
    self.locals.insert(ident, value);
  }

  /// If the Godot variable `self` is a class, returns `self`.
  /// Otherwise, returns the class of `self`. If `self` is a non-class
  /// and does not have a Godot-side class, returns None.
  pub fn get_self_class(&self) -> Option<Arc<Class>> {
    self.self_instance().get_call_target(self.bootstrapped_classes())
  }

  pub fn get_var(&self, ident: &Identifier) -> Result<Option<Value>, EvalError> {
    if let Some(local) = self.locals.get(ident) {
      return Ok(Some(local.clone()));
    }
    if let Some(class) = self.get_self_class() && Some(&*ident.0) == class.name() {
      return Ok(Some(Value::ClassRef(class)));
    }
    if let Some(glob) = self.get_global(ident)? {
      return Ok(Some(glob.clone()));
    }
    Ok(self.superglobal_state.get_var(ident).map(|x| x.clone().into()))
  }

  fn get_global(&self, ident: &Identifier) -> Result<Option<&Value>, EvalError> {
    let Some(enclosing_class) = &self.enclosing_class else {
      return Ok(None);
    };
    let Some(glob) = enclosing_class.get_constant(ident.as_ref()) else {
      return Ok(None);
    };
    glob.get(self).map(Some)
  }

  pub fn get_func(&self, ident: &Identifier) -> Option<Method> {
    if let Ok(func) = self.self_instance.get_func(ident.as_ref(), self.superglobal_state.bootstrapped_classes()) {
      return Some(func);
    }
    self.get_superglobal_func(ident).cloned()
  }

  pub fn get_superglobal_func(&self, ident: &Identifier) -> Option<&Method> {
    self.superglobal_state.get_func(ident)
  }

  pub fn get_file(&self, path: &str) -> Option<Arc<Class>> {
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
          .collect::<Result<OrderMap<_, _>, EvalError>>()?;
        Ok(Value::new_dict(entries))
      }
      Expr::Literal(lit) => {
        Ok(lit.clone().into())
      }
      Expr::Name(name) => {
        if name == "self" {
          return Ok(self.self_instance().clone());
        }
        if name == "super" {
          // If we encounter `super` anywhere *other* than an
          // immediate function call, it's an error.
          return Err(EvalError::BadSuper);
        }
        let value = self.get_var(name)?;
        if let Some(value) = value {
          return Ok(value.clone());
        }
        // Try to look up on `self`.
        if let Ok(value) = self.self_instance.get_value(name.as_ref(), &self.superglobal_state) {
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
        self.call_function_prim(self.enclosing_class.clone(), &func, self.self_instance.clone(), args)
      }
      Expr::Subscript(left, right) => {
        let left = self.eval_expr(left)?;
        let args = vec![self.eval_expr(right)?];
        // Just do it the Python way, even though Godot doesn't :)
        self.call_function_on(&left, GETITEM_METHOD_NAME, args)
      }
      Expr::Attr(left, name) => {
        let left = self.eval_expr(left)?;
        Ok(left.get_value(name.as_ref(), &self.superglobal_state)?)
      }
      Expr::AttrCall(left, name, args) => {
        if let Expr::Name(left_name) = left.as_ref() && left_name == "super" {
          // super call
          let left_value = self.self_instance().clone();
          let Some(left_class) = &self.enclosing_class else { return Err(EvalError::BadSuper); };
          let Some(left_parent) = left_class.parent() else { return Err(EvalError::BadSuper); };
          let func = left_parent.get_func(name.as_ref())?.clone();
          let args = args.iter().map(|arg| self.eval_expr(arg)).collect::<Result<Vec<_>, _>>()?;
          self.call_function_prim(Some(left_parent.clone()), &func, Box::new(left_value), MethodArgs(args))
        } else {
          let left_value = self.eval_expr(left)?;
          let args = args.iter().map(|arg| self.eval_expr(arg)).collect::<Result<Vec<_>, _>>()?;
          self.call_function_on(&left_value, name.as_ref(), args)
        }
      }
      Expr::BinaryOp(left, op, right) => {
        let left = self.eval_expr(left)?;
        // Handle short-circuiting ops
        match op {
          BinaryOp::And => {
            if left.as_bool() {
              self.eval_expr(right)
            } else {
              Ok(Value::Bool(false))
            }
          }
          BinaryOp::Or => {
            if left.as_bool() {
              Ok(left.clone())
            } else {
              self.eval_expr(right)
            }
          }
          op => {
            let right = self.eval_expr(right)?;
            eval_binary_op(self.superglobal_state.bootstrapped_classes(), left, *op, right)
          }
        }
      }
      Expr::UnaryOp(op, right) => {
        let right = self.eval_expr(right)?;
        eval_unary_op(*op, right)
      }
      Expr::Await(expr) => {
        // Whee, ignore `await` expressions!
        self.eval_expr(expr)
      }
      Expr::Lambda(lambda) => {
        let outer_scope = self.clone();
        let lambda_value = LambdaValue {
          contents: Arc::clone(lambda),
          outer_scope,
        };
        Ok(Value::Lambda(EqPtr::new(lambda_value)))
      }
      Expr::Conditional { if_true, cond, if_false } => {
        let cond = self.eval_expr(cond)?;
        if cond.as_bool() {
          self.eval_expr(if_true)
        } else {
          self.eval_expr(if_false)
        }
      }
      Expr::NewSignal => {
        Ok(Value::SignalStub)
      }
    }
  }

  pub fn eval_expr_for_assignment(&self, expr: &Expr) -> Result<AssignmentLeftHand, EvalError> {
    match expr {
      Expr::Name(name) => {
        Ok(AssignmentLeftHand::Name(name.clone().into()))
      }
      Expr::Subscript(left, right) => {
        let left = self.eval_expr(left)?;
        let right = self.eval_expr(right)?;
        Ok(AssignmentLeftHand::Subscript(left, right))
      }
      Expr::Attr(left, name) => {
        let left = self.eval_expr(left)?;
        Ok(AssignmentLeftHand::Attr(left, name.clone().into()))
      }
      other => {
        Err(EvalError::CannotAssignTo(other.clone()))
      }
    }
  }

  pub fn eval_assignment_left_hand_as_expr(&self, left_hand: &AssignmentLeftHand) -> Result<Value, EvalError> {
    match left_hand {
      AssignmentLeftHand::Name(name) => {
        self.eval_expr(&Expr::Name(name.clone().into()))
      }
      AssignmentLeftHand::Subscript(left, right) => {
        // Just do it the Python way, even though Godot doesn't :)
        self.call_function_on(left, GETITEM_METHOD_NAME, vec![right.clone()])
      }
      AssignmentLeftHand::Attr(left, name) => {
        Ok(left.get_value(name.as_ref(), &self.superglobal_state)?)
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
        if self.eval_expr(&if_stmt.condition)?.as_bool() {
          self.eval_body(&if_stmt.body)?;
        } else {
          let mut matched = false;
          for elif_clause in &if_stmt.elif_clauses {
            if self.eval_expr(&elif_clause.condition)?.as_bool() {
              self.eval_body(&elif_clause.body)?;
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
        while self.eval_expr(&while_stmt.condition)?.as_bool() {
          let inner_res = self.eval_body(&while_stmt.body);
          if let Some(cf) = ControlFlow::extract_loop_control(inner_res)? {
            if cf == LoopControlFlow::Break {
              break;
            }
          }
        }
      }
      Stmt::For(for_stmt) => {
        let iterable = self.eval_expr(&for_stmt.iterable)?.try_iter()?;
        for elem in iterable {
          self.set_local_var(for_stmt.variable.clone(), elem);
          if let Some(cf) = ControlFlow::extract_loop_control(self.eval_body(&for_stmt.body))? {
            if cf == LoopControlFlow::Break {
              break;
            }
          }
        }
      }
      Stmt::Match(match_stmt) => {
        let value = self.eval_expr(&match_stmt.value)?;
        for clause in &match_stmt.clauses {
          if value.matches(&clause.pattern) {
            self.eval_body(&clause.body)?;
            break;
          }
        }
      }
      Stmt::AssignOp(left, op, right) => {
        let left_hand = self.eval_expr_for_assignment(left)?;
        if *op == AssignOp::Eq {
          // Basic assignment
          self.do_assignment(left_hand, self.eval_expr(right)?)?;
        } else {
          let bin_op = op.as_binary().expect("Expected compound assignment");
          let left = self.eval_assignment_left_hand_as_expr(&left_hand)?;
          let right = self.eval_expr(right)?;
          self.do_assignment(left_hand, eval_binary_op(self.superglobal_state.bootstrapped_classes(), left, bin_op, right)?)?;
        }
      }
    }
    Ok(())
  }

  pub fn do_assignment(&mut self,
                       left_hand: AssignmentLeftHand,
                       value: Value) -> Result<(), EvalError> {
    match left_hand {
      AssignmentLeftHand::Name(id) => {
        if self.has_local_var(&id) {
          self.set_local_var(id, value);
        } else {
          self.self_instance().set_value(id.as_ref(), value, self.superglobal_state())?;
        }
      }
      AssignmentLeftHand::Subscript(left, index) => {
        left.set_index(index, value)?;
      }
      AssignmentLeftHand::Attr(left, name) => {
        left.set_value(name.as_ref(), value, self.superglobal_state())?;
      }
    }
    Ok(())
  }

  pub fn call_function_on(&self,
                          receiver: &Value,
                          method_name: &str,
                          args: Vec<Value>) -> Result<Value, EvalError> {
    let method = receiver.get_func(method_name, self.bootstrapped_classes())?;
    let globals = receiver.get_call_target(self.bootstrapped_classes());
    self.call_function_prim(globals, &method, Box::new(receiver.clone()), MethodArgs(args))
  }

  pub fn call_function_on_class(&self,
                                receiver: &Arc<Class>,
                                method_name: &str,
                                args: Vec<Value>) -> Result<Value, EvalError> {
    let method = if method_name == "new" {
      Method::constructor_method()
    } else {
      receiver.get_func(method_name)?.clone()
    };
    self.call_function_prim(Some(receiver.clone()), &method, Box::new(Value::ClassRef(Arc::clone(receiver))), MethodArgs(args))
  }

  /// Primitive, low-level function call method.
  pub fn call_function_prim(&self,
                            globals: Option<Arc<Class>>,
                            method: &Method,
                            self_instance: Box<Value>,
                            args: MethodArgs) -> Result<Value, EvalError> {
    fn run_body(state: &EvaluatorState,
                globals: Option<Arc<Class>>,
                method: &Method,
                self_instance: Box<Value>,
                args: MethodArgs) -> Result<Value, EvalError> {
      let mut method_scope = state.clone().with_self(self_instance);
      if let Some(globals) = globals {
        method_scope = method_scope.with_enclosing_class(Some(globals));
      }
      method.call(&mut method_scope, args)
    }
    run_body(self, globals, method, self_instance, args)
      .map_err(|err| err.with_function_context(method.name().as_ref()))
  }

  /// Bind arguments for a function call. In case of error, `self` is
  /// guaranteed to be unmodified.
  pub fn bind_arguments(&mut self, func_name: &str, args: Vec<Value>, params: Vec<Parameter>) -> Result<(), EvalError> {
    let args_len = args.len();
    let params_len = params.len();
    let required_params_len = params.iter().filter(|param| param.default_value.is_none()).count();
    let mut bindings = Vec::with_capacity(params_len);
    let mut args = args.into_iter();
    for param in params {
      let next_arg;
      if let Some(provided_arg) = args.next() {
        next_arg = provided_arg;
      } else if let Some(expr) = &param.default_value {
        next_arg = self.eval_expr(expr)?;
      } else {
        let expected_arity = ExpectedArity::between(required_params_len, params_len);
        return Err(EvalError::WrongArity {
          function: func_name.to_owned(),
          expected: expected_arity,
          actual: args_len,
        });
      }
      bindings.push((param.name, next_arg));
    }
    for (param, arg) in bindings {
      self.set_local_var(param.into(), arg);
    }
    Ok(())
  }

  pub fn do_random<F, R>(&self, func: F) -> R
  where F: FnOnce(&mut dyn RngCore) -> R {
    func(&mut self.random_generator.borrow_mut())
  }
}

impl SuperglobalState {
  pub fn new() -> Self {
    let mut result = Self {
      vars: HashMap::new(),
      functions: HashMap::new(),
      loaded_files: HashMap::new(),
      bootstrapped_classes: BootstrappedTypes::bootstrap(),
    };
    for (name, cls) in result.bootstrapped_classes.all_global_names() {
      result.vars.insert(Identifier::new(name), SimpleValue::ClassRef(cls));
    }
    result
  }

  pub fn bootstrapped_classes(&self) -> &BootstrappedTypes {
    &self.bootstrapped_classes
  }

  pub fn bind_var(&mut self, ident: Identifier, value: SimpleValue) {
    self.vars.insert(ident, value);
  }

  pub fn bind_class(&mut self, ident: Identifier, class: Arc<Class>) {
    self.bind_var(ident, SimpleValue::ClassRef(class));
  }

  pub fn define_func(&mut self, ident: Identifier, func: Method) {
    self.functions.insert(ident, func);
  }

  pub fn add_file(&mut self, path: ResourcePath, class: Arc<Class>) {
    self.loaded_files.insert(path, class);
  }

  pub fn load_file(&mut self, path: ResourcePath, source_file: SourceFile) -> Result<(), EvalError> {
    self.load_file_with(path, source_file, |builder| builder)
  }

  pub fn load_file_with<F>(&mut self, path: ResourcePath, source_file: SourceFile, augmentation: F) -> Result<(), EvalError>
    where F: FnOnce(ClassBuilder) -> ClassBuilder {
    let class = Class::load_from_file_with(self, source_file, augmentation)?;
    let class = Arc::new(class);
    self.loaded_files.insert(path, Arc::clone(&class));
    if let Some(class_name) = class.name() {
      self.bind_var(class_name.to_owned().into(), SimpleValue::ClassRef(class));
    }
    Ok(())
  }

  pub fn get_var<Q>(&self, ident: &Q) -> Option<&SimpleValue>
  where Identifier: Borrow<Q>,
        Q: Hash + Eq + ?Sized {
    self.vars.get(ident)
  }

  pub fn get_func<Q>(&self, ident: &Q) -> Option<&Method>
  where Identifier: Borrow<Q>,
        Q: Hash + Eq + ?Sized {
    self.functions.get(ident)
  }

  pub fn get_file<Q>(&self, path: &Q) -> Option<Arc<Class>>
  where ResourcePath: Borrow<Q>,
        Q: Hash + Eq + ?Sized {
    self.loaded_files.get(path).cloned()
  }
}

impl Default for SuperglobalState {
  fn default() -> Self {
    Self::new()
  }
}
