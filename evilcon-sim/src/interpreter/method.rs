
use crate::ast::decl::FunctionDecl;
use crate::ast::identifier::Identifier;
use super::eval::EvaluatorState;
use super::error::EvalError;
use super::value::Value;

use std::sync::Arc;
use std::fmt::{Formatter, Debug};

#[derive(Debug, Clone)]
pub enum Method {
  /// Method defined in GDScript code.
  GdMethod(Arc<FunctionDecl>),
  /// Method written in Rust.
  RustMethod(RustMethod),
}

#[derive(Clone)]
pub struct RustMethod {
  pub name: Identifier,
  pub is_static: bool,
  pub body: Arc<dyn Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError>>,
}

#[derive(Debug, Clone)]
pub struct MethodArgs(pub Vec<Value>);

impl Method {
  pub fn name(&self) -> &Identifier {
    match self {
      Method::GdMethod(decl) => &decl.name,
      Method::RustMethod(m) => &m.name,
    }
  }

  pub fn rust_method(name: impl Into<Identifier>,
                     body: impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + 'static) -> Method {
    Method::RustMethod(RustMethod {
      name: name.into(),
      is_static: false,
      body: Arc::new(body),
    })
  }

  pub fn rust_static_method(name: impl Into<Identifier>,
                            body: impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + 'static) -> Method {
    Method::RustMethod(RustMethod {
      name: name.into(),
      is_static: true,
      body: Arc::new(body),
    })
  }

  pub fn constructor_method() -> Method {
    fn body(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
      let Some(Value::ClassRef(class)) = state.self_instance() else {
        return Err(EvalError::type_error("class", state.self_instance().cloned().unwrap_or_default()));
      };
      let new_inst = Value::new_object(Arc::clone(class));
      if let Ok(init_method) = class.get_func("_init") {
        state.call_function(Some(Arc::clone(&class.constants)), init_method, Some(Box::new(new_inst.clone())), args)?;
      }
      Ok(new_inst)
    }
    Self::rust_method("new", body)
  }

  pub fn noop() -> Method {
    fn body(_: &mut EvaluatorState, _: MethodArgs) -> Result<Value, EvalError> {
      Ok(Value::Null)
    }
    Self::rust_method("noop", body)
  }

  pub fn is_static(&self) -> bool {
    match self {
      Method::GdMethod(m) => m.is_static,
      Method::RustMethod(m) => m.is_static,
    }
  }
}

impl MethodArgs {
  pub const EMPTY: MethodArgs = MethodArgs(Vec::new());

  pub fn is_empty(&self) -> bool {
    self.0.is_empty()
  }

  pub fn len(&self) -> usize {
    self.0.len()
  }

  pub fn expect_arity(&self, arity: usize) -> Result<(), EvalError> {
    if self.0.len() != arity {
      Err(EvalError::WrongArity { expected: arity, actual: self.0.len() })
    } else {
      Ok(())
    }
  }
}

impl Debug for RustMethod {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    f.debug_struct("RustMethod")
      .field("name", &self.name)
      .field("body", &"<fn>")
      .finish()
  }
}
