
use crate::interpreter::class::{Class, ClassBuilder, InstanceVar, ProxyVar};
use crate::interpreter::class::proxy::{ProxyField, BackedField};
use crate::interpreter::method::Method;
use crate::interpreter::value::Value;
use crate::interpreter::eval::SuperglobalState;
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::expect_int;
use crate::ast::expr::Expr;
use crate::ast::identifier::Identifier;
use crate::util::clamp;

use std::sync::Arc;
use std::collections::HashMap;

pub const DESTINY_SONG_LIMIT: i64 = 3;
pub const DEFAULT_FORT_DEFENSE: i64 = 60;

pub(super) fn game_stats_panel_class(node: Arc<Class>) -> Class {
  let mut vars = Vec::new();
  vars.push(InstanceVar::new("__evilconsim_evil_points", Some(Expr::from(0))));
  vars.push(InstanceVar::new("__evilconsim_fort_defense", Some(Expr::from(DEFAULT_FORT_DEFENSE))));
  vars.push(InstanceVar::new("__evilconsim_max_fort_defense", Some(Expr::from(DEFAULT_FORT_DEFENSE))));
  vars.push(InstanceVar::new("__evilconsim_destiny_song", Some(Expr::from(0))));

  let mut proxies = HashMap::new();
  proxies.insert(Identifier::new("evil_points"), ProxyVar::new(
    BackedField::new("__evilconsim_evil_points").clamped_above(0),
  ));
  proxies.insert(Identifier::new("fort_defense"), ProxyVar::new(
    FortDefenseProxyField {
      curr_field_name: "__evilconsim_fort_defense",
      max_field_name: "__evilconsim_max_fort_defense",
    },
  ));
  proxies.insert(Identifier::new("max_fort_defense"), ProxyVar::new(
    MaxFortDefenseProxyField {
      curr_proxy_name: "fort_defense",
      max_field_name: "__evilconsim_max_fort_defense",
    },
  ));
  proxies.insert(Identifier::new("destiny_song"), ProxyVar::new(
    BackedField::new("__evilconsim_destiny_song").clamped(0, DESTINY_SONG_LIMIT),
  ));

  let mut methods = HashMap::new();
  methods.insert(Identifier::new("update_stats_from"), Method::noop());

  ClassBuilder::default()
    .parent(node)
    .instance_vars(vars)
    .methods(methods)
    .proxy_vars(proxies)
    .build()
}

#[derive(Debug, Clone)]
struct FortDefenseProxyField {
  curr_field_name: &'static str,
  max_field_name: &'static str,
}

#[derive(Debug, Clone)]
struct MaxFortDefenseProxyField {
  curr_proxy_name: &'static str,
  max_field_name: &'static str,
}

impl ProxyField for FortDefenseProxyField {
  fn get_field(&self, superglobals: &Arc<SuperglobalState>, object: &Value) -> Result<Value, EvalError> {
    object.get_value_raw(&self.curr_field_name, superglobals)
  }

  fn set_field(&self, superglobals: &Arc<SuperglobalState>, object: &Value, value: Value) -> Result<(), EvalError> {
    let lower_bound = 0;
    let upper_bound = expect_int(&object.get_value(&self.max_field_name, superglobals)?)?;
    let new_value = clamp(expect_int(&value)?, lower_bound, upper_bound);
    object.set_value_raw(&self.curr_field_name, Value::from(new_value))?;
    Ok(())
  }
}

impl ProxyField for MaxFortDefenseProxyField {
  fn get_field(&self, superglobals: &Arc<SuperglobalState>, object: &Value) -> Result<Value, EvalError> {
    object.get_value_raw(&self.max_field_name, superglobals)
  }

  fn set_field(&self, superglobals: &Arc<SuperglobalState>, object: &Value, value: Value) -> Result<(), EvalError> {
    object.set_value_raw(&self.max_field_name, Value::from(i64::max(expect_int(&value)?, 0)))?;
    // Invoke setter for fort_defense variable as well.
    let old_fort_defense = object.get_value(&self.curr_proxy_name, superglobals)?;
    object.set_value(&self.curr_proxy_name, old_fort_defense, superglobals)?;
    Ok(())
  }
}
