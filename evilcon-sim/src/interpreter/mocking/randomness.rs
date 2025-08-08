
use crate::interpreter::class::{Class, ClassBuilder};
use crate::interpreter::value::Value;
use crate::interpreter::method::Method;
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::{expect_int, expect_array};
use crate::ast::identifier::Identifier;

use rand::Rng;
use rand::seq::IndexedRandom;

use std::sync::Arc;
use std::collections::HashMap;

pub(super) fn randomness_class(refcounted: Arc<Class>) -> Class {
  let mut methods = HashMap::new();
  methods.insert(Identifier::new("randi"), Method::rust_method("randi", |state, args| {
    args.expect_arity(0, "randi")?;
    // Match Godot semantics precisely: Godot produces an i32 here.
    let result = state.do_random(|rng| rng.random::<i32>() as i64);
    Ok(Value::from(result))
  }));

  methods.insert(Identifier::new("randi_range"), Method::rust_method("randi_range", |state, args| {
    args.expect_arity(2, "randi_range")?;
    let [from, to] = args.0.try_into().expect("Expected 2 args");
    let from = expect_int("randi_range", &from)?;
    let to = expect_int("randi_range", &to)?;
    let result = state.do_random(|rng| rng.random_range(from..=to));
    Ok(Value::from(result))
  }));

  methods.insert(Identifier::new("choose"), Method::rust_method("choose", |state, args| {
    args.expect_arity(1, "choose")?;
    let [arr] = args.0.try_into().expect("Expected 1 arg");
    let arr = expect_array("choose", &arr)?.borrow();
    let value = state.do_random(|rng| arr.choose(rng))
      .ok_or_else(|| EvalError::domain_error("Can't choose from empty array"))?;
    Ok(value.clone())
  }));

  ClassBuilder::default()
    .name("Randomness")
    .parent(refcounted)
    .methods(methods)
    .build()
}
