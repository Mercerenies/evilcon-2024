
use crate::ast::decl::FunctionDecl;
use crate::ast::identifier::Identifier;
use super::eval::EvaluatorState;
use super::error::EvalError;
use super::value::Value;

use std::rc::Rc;
use std::fmt::{Formatter, Debug};

#[derive(Debug, Clone)]
pub enum Method {
  /// Method defined in GDScript code.
  GdMethod(Rc<FunctionDecl>),
  /// Method written in Rust.
  RustMethod(RustMethod),
}

#[derive(Clone)]
pub struct RustMethod {
  pub name: Identifier,
  pub body: Rc<dyn Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError>>,
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
      body: Rc::new(body),
    })
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
