
pub mod constant;

use crate::ast::identifier::Identifier;
use crate::ast::file::SourceFile;
use crate::ast::expr::Expr;
use super::method::Method;
use super::error::EvalError;
use super::eval::SuperglobalState;
use constant::LazyConst;

use std::hash::{Hash, Hasher};
use std::rc::Rc;
use std::collections::HashMap;

/// A class written in Godot or mocked Rust-side.
#[derive(Debug, Clone)]
pub struct Class {
  pub name: Option<String>,
  pub parent: Option<Rc<Class>>,
  pub constants: Rc<HashMap<Identifier, LazyConst>>,
  pub instance_vars: Vec<InstanceVar>,
  pub methods: HashMap<Identifier, Method>,
}

#[derive(Debug, Clone)]
pub struct InstanceVar {
  pub name: Identifier,
  pub initial_value: Expr,
}

impl Class {
  pub fn load_from_file(superglobals: &mut SuperglobalState, file: SourceFile) -> Result<Self, EvalError> {
    let name = file.class_name;
    todo!()
  }
}

impl PartialEq for Class {
  fn eq(&self, other: &Self) -> bool {
    self.name == other.name
  }
}

impl Eq for Class {}

impl Hash for Class {
  fn hash<H: Hasher>(&self, state: &mut H) {
    self.name.hash(state)
  }
}
