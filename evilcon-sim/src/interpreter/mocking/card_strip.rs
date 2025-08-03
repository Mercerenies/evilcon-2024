
use crate::interpreter::class::{Class, ClassBuilder, InstanceVar};
use crate::interpreter::method::{Method, MethodArgs};
use crate::interpreter::value::Value;
use crate::interpreter::error::EvalError;
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::operator::expect_string;
use crate::ast::identifier::Identifier;
use crate::ast::expr::Expr;
use super::dummy_class;

use std::sync::Arc;
use std::collections::HashMap;

pub(super) const CARD_STRIP_RES_PATH: &str = "res://card_game/playing_field/card_strip/card_strip.gd";

pub(super) fn card_strip_class(node: Arc<Class>) -> Class {
  let cards_initial_value =
    Expr::call("load", vec![Expr::string("res://card_game/playing_field/card_container/card_container.gd")])
    .attr_call("new", Vec::new());

  let mut instance_vars = Vec::new();
  instance_vars.push(InstanceVar::new("__evilconsim_cards", Some(cards_initial_value)));
  instance_vars.push(InstanceVar::new("card_added", Some(Expr::NewSignal)));
  instance_vars.push(InstanceVar::new("cards_modified", Some(Expr::NewSignal)));

  let mut methods = HashMap::new();
  methods.insert(Identifier::new("_init"), Method::rust_method("_init", card_strip_constructor));
  methods.insert(Identifier::new("get_card_node"), Method::noop()); // Needed for CardGameApi
  methods.insert(Identifier::new("card_nodes"), Method::unimplemented_stub("card_nodes unimplemented"));
  methods.insert(Identifier::new("cards"), Method::rust_method("cards", |state, args| {
    args.expect_arity(0, "cards")?;
    state.self_instance().get_value("__evilconsim_cards", state.superglobal_state())
  }));

  ClassBuilder::default()
    .parent(node)
    .instance_vars(instance_vars)
    .methods(methods)
    .build()
}

pub(super) fn card_strip_tscn_class() -> Class {
  // This .tscn should never be used.
  dummy_class()
}

// Complete custom method so our mocked PlayingField can do setup
// properly.
fn card_strip_constructor(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let card_kind = args.expect_one_arg("_init")?;
  let card_kind = expect_string(&card_kind)?;
  let card_container = state.self_instance().get_value("__evilconsim_cards", state.superglobal_state())?;
  card_container.set_value("contained_type", Value::from(card_kind), state.superglobal_state())?;
  Ok(Value::Null)
}
