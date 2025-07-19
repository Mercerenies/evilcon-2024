
//! Mocked classes that are *not* necessarily for bootstrapping.
//!
//! Interpreter-critical classes like `Array` belong in
//! `bootstrapping.rs`, not here.

use super::class::Class;
use super::class::constant::LazyConst;
use super::value::Value;
use super::eval::SuperglobalState;
use crate::ast::identifier::{Identifier, ResourcePath};

use std::sync::Arc;
use std::collections::HashMap;

pub fn bind_mocked_classes(superglobals: &mut SuperglobalState) {
  // Node
  let node = node_class(Arc::clone(superglobals.bootstrapped_classes().object()));
  let node = Arc::new(node);
  superglobals.bind_class(Identifier::new("Node"), Arc::clone(&node));

  // PopupText
  let popup_text = popup_text_class(Arc::clone(&node));
  let popup_text = Arc::new(popup_text);
  superglobals.bind_class(Identifier::new("PopupText"), Arc::clone(&popup_text));
  superglobals.add_file(ResourcePath::new("res://card_game/playing_field/util/popup_text.gd"), popup_text);
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

fn popup_text_class(node: Arc<Class>) -> Class {
  const CONST_NAMES: [&str; 6] = ["NO_TARGET", "BLOCKED", "CLOWNED", "DEMONED", "ROBOTED", "WILDED"];
  let mut constants = HashMap::new();
  for const_name in CONST_NAMES {
    constants.insert(Identifier::new(const_name), LazyConst::resolved(Value::from("UNUSED CONSTANT")));
  }
  let methods = HashMap::new();
  Class {
    name: Some(String::from("PopupText")),
    parent: Some(node),
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}
