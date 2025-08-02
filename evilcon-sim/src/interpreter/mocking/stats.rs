
use crate::interpreter::class::{Class, ClassBuilder, InstanceVar, ProxyVar};
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::method::Method;
use crate::interpreter::value::Value;
use crate::interpreter::eval::{SuperglobalState, EvaluatorState};
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::expect_int;
use crate::ast::expr::Expr;
use crate::ast::identifier::Identifier;
use crate::util::clamp;

use std::sync::Arc;
use std::collections::HashMap;

const TARGET_TEXT_VALUES: &[(&str, &str)] = &[
  ("NO_TARGET", "No Target!"),
  ("BLOCKED", "Blocked!"),
  ("CLOWNED", "Clowned!"),
  ("DEMONED", "Bedeviled!"),
  ("ROBOTED", "Upgraded!"),
];

pub(super) fn stats_static_class(node: Arc<Class>) -> Class {
  let mut constants = HashMap::new();
  constants.insert(Identifier::new("NumberAnimation"), LazyConst::null());
  constants.insert(Identifier::new("GameStatsDict"), LazyConst::null());
  constants.insert(Identifier::new("CARD_MULTI_UI_OFFSET"), LazyConst::null());
  for (var_prefix, str_value) in TARGET_TEXT_VALUES {
    constants.insert(Identifier::new(format!("{var_prefix}_TEXT")), LazyConst::resolved(Value::from(*str_value)));
    constants.insert(Identifier::new(format!("{var_prefix}_COLOR")), LazyConst::null());
  }

  let mut methods = HashMap::new();
  methods.insert(Identifier::new("play_animation_for_stat_change"), Method::static_noop());
  methods.insert(Identifier::new("show_text"), Method::static_noop());

  ClassBuilder::default()
    .name("Stats")
    .parent(node)
    .constants(constants)
    .methods(methods)
    .build()
}
