
use crate::interpreter::class::{Class, InstanceVar};
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::value::Value;
use crate::interpreter::method::Method;
use crate::interpreter::eval::SuperglobalState;
use crate::ast::expr::Expr;
use crate::ast::identifier::{Identifier, ResourcePath};

use std::sync::Arc;
use std::collections::HashMap;

pub(super) fn playing_field_class(node: Arc<Class>) -> Class {
  let mut constants = HashMap::new();
  constants.insert(Identifier::new("SECOND_PLAYER_FORT_ADVANTAGE"), LazyConst::resolved(Value::from(2)));
  constants.insert(Identifier::new("Randomness"), LazyConst::preload("res://card_game/playing_field/randomness.gd"));
  constants.insert(Identifier::new("EventLogger"), LazyConst::preload("res://card_game/playing_field/event_logger.gd"));

  let mut instance_vars = Vec::new();
  instance_vars.push(InstanceVar::new("turn_number", Some(Expr::from(-1))));
  instance_vars.push(InstanceVar::new("randomness", Some(
    Expr::name("Randomness").attr_call("new", vec![]),
  )));
  instance_vars.push(InstanceVar::new("event_logger", Some(
    Expr::name("EventLogger").attr_call("new", vec![]),
  )));
  instance_vars.push(InstanceVar::new("top_cards_are_hidden", Some(Expr::from(true))));
  instance_vars.push(InstanceVar::new("top_cards_are_hidden", Some(Expr::from(false))));
  instance_vars.push(InstanceVar::new("plays_animations", Some(Expr::from(false))));

  let mut methods = HashMap::new();
  methods.insert(Identifier::new("with_animation"), Method::noop());

  // TODO More

  Class {
    name: None,
    parent: Some(node),
    constants: Arc::new(constants),
    instance_vars,
    methods,
  }
}

pub(super) fn randomness_class(refcounted: Arc<Class>) -> Class {
  let constants = HashMap::new();
  let methods = HashMap::new();

  // TODO Methods on this

  Class {
    name: Some(String::from("Randomness")),
    parent: Some(refcounted),
    constants: Arc::new(constants),
    instance_vars: vec![],
    methods,
  }
}
