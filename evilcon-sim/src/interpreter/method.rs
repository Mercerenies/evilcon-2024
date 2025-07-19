
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

  pub fn is_static(&self) -> bool {
    match self {
      Method::GdMethod(m) => m.is_static,
      Method::RustMethod(m) => m.is_static,
    }
  }
}

impl MethodArgs {
  pub fn is_empty(&self) -> bool {
    self.0.is_empty()
  }

  pub fn len(&self) -> usize {
    self.0.len()
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
