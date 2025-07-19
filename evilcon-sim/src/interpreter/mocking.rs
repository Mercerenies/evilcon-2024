
//! Mocked classes that are *not* necessarily for bootstrapping.
//!
//! Interpreter-critical classes like `Array` belong in
//! `bootstrapping.rs`, not here.

use super::class::Class;
use super::eval::SuperglobalState;
use crate::ast::identifier::Identifier;

use std::sync::Arc;
use std::collections::HashMap;

pub fn bind_mocked_classes(superglobals: &mut SuperglobalState) {
  let node = node_class(Arc::clone(superglobals.bootstrapped_classes().object()));
  superglobals.bind_class(Identifier::new("Node"), Arc::new(node));
}

fn node_class(object: Arc<Class>) -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();
  Class {
    name: Some(String::from("Node")),
    parent: Some(object),
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}
