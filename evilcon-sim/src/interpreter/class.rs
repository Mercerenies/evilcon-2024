
use crate::ast::identifier::Identifier;
use super::value::Value;
use super::method::Method;

use std::hash::{Hash, Hasher};
use std::rc::Rc;
use std::collections::HashMap;

/// A class written in Godot or mocked Rust-side.
#[derive(Debug, Clone)]
pub struct Class {
  pub name: Option<String>,
  pub parent: Option<Rc<Class>>,
  pub constants: Rc<HashMap<Identifier, Value>>,
  pub instance_vars: Vec<InstanceVar>,
  pub methods: HashMap<Identifier, Method>,
}

#[derive(Debug, Clone)]
pub struct InstanceVar {
  pub name: Identifier,
  pub initial_value: Value,
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
