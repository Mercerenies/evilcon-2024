
use crate::interpreter::class::{Class, ClassBuilder, InstanceVar};
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::value::Value;
use crate::interpreter::eval::EvaluatorState;
use crate::interpreter::method::{Method, MethodArgs};
use crate::interpreter::operator::expect_string;
use crate::interpreter::error::EvalError;
use crate::ast::expr::{Expr, Literal};
use crate::ast::identifier::Identifier;
use super::card_strip::CARD_STRIP_RES_PATH;
use super::stats_panel::STATS_PANEL_RES_PATH;

use std::sync::Arc;
use std::collections::HashMap;

pub const ENDGAME_VARIABLE: &str = "__evilconsim_endgame";

// Intentionally omitted:
// * _ready (all AI setup and node setup that we do by hand)
// * replace_player_agent (will be done by hand)
// * popup_display_card (visual stuff)
// * player_agent (only used in turn transitions)
// * Like twenty signal response methods that do nothing but animations and input
// * Several private internal helpers
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
  instance_vars.push(InstanceVar::new("__evilconsim_deck_bottom", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_deck_top", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_discardpile_bottom", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_discardpile_top", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_hand_bottom", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_hand_top", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_minionstrip_bottom", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_minionstrip_top", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_effectstrip_bottom", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_effectstrip_top", Some(instantiate_card_strip())));
  instance_vars.push(InstanceVar::new("__evilconsim_statspanel_top", Some(instantiate_stats_panel())));
  instance_vars.push(InstanceVar::new("__evilconsim_statspanel_bottom", Some(instantiate_stats_panel())));
  instance_vars.push(InstanceVar::new(ENDGAME_VARIABLE, Some(Expr::Literal(Literal::Null))));

  let mut methods = HashMap::new();
  methods.insert(Identifier::new("with_animation"), Method::noop());
  methods.insert(Identifier::new("emit_cards_moved"), Method::noop());
  methods.insert(Identifier::new("get_deck"), selector_function("__evilconsim_deck_bottom", "__evilconsim_deck_top"));
  methods.insert(Identifier::new("get_discard_pile"), selector_function("__evilconsim_discardpile_bottom", "__evilconsim_discardpile_top"));
  methods.insert(Identifier::new("get_hand"), selector_function("__evilconsim_hand_bottom", "__evilconsim_hand_top"));
  methods.insert(Identifier::new("get_minion_strip"), selector_function("__evilconsim_minionstrip_bottom", "__evilconsim_minionstrip_top"));
  methods.insert(Identifier::new("get_effect_strip"), selector_function("__evilconsim_effectstrip_bottom", "__evilconsim_effectstrip_top"));
  methods.insert(Identifier::new("get_stats"), selector_function("__evilconsim_statspanel_bottom", "__evilconsim_statspanel_top"));
  methods.insert(Identifier::new("end_game"), Method::rust_method("end_game", end_game_method));
  methods.insert(Identifier::new("get_viewport_rect"), Method::rust_method("get_viewport_rect", get_viewport_rect));
  methods.insert(Identifier::new("animate_card_moving"), Method::noop());
  methods.insert(Identifier::new("hand_cards_are_hidden"), Method::rust_method("hand_cards_are_hidden", hand_cards_are_hidden));

  ClassBuilder::default()
    .parent(node)
    .constants(constants)
    .instance_vars(instance_vars)
    .methods(methods)
    .build()
}

fn instantiate_card_strip() -> Expr {
  Expr::call("load", vec![Expr::string(CARD_STRIP_RES_PATH)])
    .attr_call("new", vec![])
}

fn instantiate_stats_panel() -> Expr {
  Expr::call("load", vec![Expr::string(STATS_PANEL_RES_PATH)])
    .attr_call("new", vec![])
}

/// A Godot-side method that selects between two instance variables on
/// `self`.
fn selector_function(bottom_var: &str, top_var: &str) -> Method {
  let bottom_var = bottom_var.to_owned();
  let top_var = top_var.to_owned();
  let method_body = move |evaluator: &mut EvaluatorState, args: MethodArgs| {
    let arg = args.expect_one_arg()?;
    match expect_string(&arg)? {
      "BOTTOM" => evaluator.self_instance().get_value(&bottom_var, evaluator.superglobal_state()),
      "TOP" => evaluator.self_instance().get_value(&top_var, evaluator.superglobal_state()),
      _ => {
        eprintln!("Bad card player {}", arg);
        Ok(Value::Null)
      }
    }
  };
  Method::rust_method("getter", method_body)
}

fn end_game_method(evaluator: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
  let winner = args.expect_one_arg()?;
  // If the game calls this method twice, only the first call should
  // have any effect.
  let old_value = evaluator.self_instance().get_value(ENDGAME_VARIABLE, evaluator.superglobal_state())?;
  if old_value == Value::Null {
    evaluator.self_instance().set_value(ENDGAME_VARIABLE, winner, evaluator.superglobal_state())?;
  }
  Ok(Value::Null)
}

fn get_viewport_rect(evaluator: &mut EvaluatorState, _: MethodArgs) -> Result<Value, EvalError> {
  // This is a hack specifically for Mystery Box. Mystery Box treats
  // the playing field as a Godot node and gets the viewport rect. I
  // don't actually care what this value is, just that it exists and
  // is duck-typed to look like what I need in MysteryBox._get_origin.
  let object_class = evaluator.bootstrapped_classes().object();
  let black_hole_object = Value::new_object(Arc::clone(object_class));
  black_hole_object.set_value("size", Value::from(0), evaluator.superglobal_state())?;
  Ok(black_hole_object)
}

fn hand_cards_are_hidden(_: &mut EvaluatorState, _: MethodArgs) -> Result<Value, EvalError> {
  Ok(Value::from(false))
}
