
use crate::interpreter::class::{Class, InstanceVar};
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::value::Value;
use crate::interpreter::method::Method;
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::{expect_int, expect_array};
use crate::ast::expr::Expr;
use crate::ast::identifier::Identifier;

use rand::{Rng, rng};
use rand::seq::IndexedRandom;

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
  let mut methods = HashMap::new();
  methods.insert(Identifier::new("randi"), Method::rust_method("randi", |_, args| {
    args.expect_arity(0)?;
    let mut rng = rng();
    // Match Godot semantics precisely: Godot produces an i32 here.
    Ok(Value::from(rng.random::<i32>() as i64))
  }));

  methods.insert(Identifier::new("randi_range"), Method::rust_method("randi_range", |_, args| {
    args.expect_arity(2)?;
    let [from, to] = args.0.try_into().expect("Expected 2 args");
    let from = expect_int(&from)?;
    let to = expect_int(&to)?;
    let mut rng = rng();
    Ok(Value::from(rng.random_range(from..=to)))
  }));

  methods.insert(Identifier::new("choose"), Method::rust_method("choose", |_, args| {
    args.expect_arity(1)?;
    let [arr] = args.0.try_into().expect("Expected 1 arg");
    let arr = expect_array(&arr)?.borrow();
    let value = arr.choose(&mut rng())
      .ok_or_else(|| EvalError::domain_error("Can't choose from empty array"))?;
    Ok(value.clone())
  }));

  Class {
    name: Some(String::from("Randomness")),
    parent: Some(refcounted),
    constants: Arc::new(HashMap::new()),
    instance_vars: vec![],
    methods,
  }
}
