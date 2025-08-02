
use crate::interpreter::class::{Class, ClassBuilder, InstanceVar};
use crate::interpreter::method::Method;
use crate::ast::expr::Expr;
use crate::ast::identifier::Identifier;
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
  methods.insert(Identifier::new("get_card_node"), Method::noop()); // Needed for CardGameApi
  methods.insert(Identifier::new("card_nodes"), Method::unimplemented_stub("card_nodes unimplemented"));
  methods.insert(Identifier::new("cards"), Method::rust_method("cards", |state, args| {
    args.expect_arity(0)?;
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
