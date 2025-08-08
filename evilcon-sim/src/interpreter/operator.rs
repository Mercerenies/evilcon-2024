
use crate::ast::expr::operator::{BinaryOp, UnaryOp};
use crate::ast::string::formatter::format_percent;
use super::value::{Value, HashKey};
use super::error::EvalError;
use super::bootstrapping::BootstrappedTypes;

use ordered_float::OrderedFloat;
use ordermap::OrderMap;

use std::cmp::Ordering;
use std::sync::Arc;
use std::cell::RefCell;
use std::fmt::Display;

pub fn eval_unary_op(op: UnaryOp, value: Value) -> Result<Value, EvalError> {
  match op {
    UnaryOp::Not => Ok(Value::Bool(!value.as_bool())),
    UnaryOp::Pos => Ok(value),
    UnaryOp::Neg => {
      match value {
        Value::Int(n) => Ok(Value::Int(-n)),
        Value::Float(f) => Ok(Value::Float(-f)),
        value => Err(EvalError::type_error(op.to_string(), "number", value)),
      }
    }
    UnaryOp::Compl => {
      // Don't think I need it
      unimplemented!()
    }
  }
}

pub fn eval_binary_op(bootstrapping: &BootstrappedTypes, lhs: Value, op: BinaryOp, rhs: Value) -> Result<Value, EvalError> {
  match op {
    BinaryOp::Add => {
      if matches!(lhs, Value::ArrayRef(_)) {
        do_array_concat(lhs, rhs)
      } else {
        promote_binary_nums(&op, lhs, rhs, |lhs, rhs| Ok(lhs + rhs), |lhs, rhs| Ok(lhs + rhs))
      }
    }
    BinaryOp::Sub => promote_binary_nums(&op, lhs, rhs, |lhs, rhs| Ok(lhs - rhs), |lhs, rhs| Ok(lhs - rhs)),
    BinaryOp::Mul => promote_binary_nums(&op, lhs, rhs, |lhs, rhs| Ok(lhs * rhs), |lhs, rhs| Ok(lhs * rhs)),
    BinaryOp::Div => promote_binary_nums(&op, lhs, rhs, |lhs, rhs| Ok(lhs / rhs), |lhs, rhs| Ok(lhs / rhs)), // Note: Integer division on ints
    BinaryOp::Mod => {
      match lhs {
        Value::Int(lhs) => {
          // Integer modulo
          let rhs = expect_int("%", &rhs)?;
          Ok(Value::Int(lhs % rhs))
        }
        Value::String(lhs) => {
          // String formatting
          let rhs = match rhs {
            Value::ArrayRef(arr) => arr.borrow().clone(),
            rhs => vec![rhs],
          };
          let out_str = format_percent(&lhs, &rhs)?;
          Ok(Value::String(out_str.into_owned()))
        }
        _ => {
          Err(EvalError::type_error(op.to_string(), "string or number", lhs))
        }
      }
    }
    BinaryOp::Eq => Ok(Value::Bool(lhs == rhs)),
    BinaryOp::Ne => Ok(Value::Bool(lhs != rhs)),
    BinaryOp::Lt => do_comparison_op(&lhs, &rhs).map(|ord| Value::Bool(ord == Ordering::Less)),
    BinaryOp::Le => do_comparison_op(&lhs, &rhs).map(|ord| Value::Bool(ord != Ordering::Greater)),
    BinaryOp::Gt => do_comparison_op(&lhs, &rhs).map(|ord| Value::Bool(ord == Ordering::Greater)),
    BinaryOp::Ge => do_comparison_op(&lhs, &rhs).map(|ord| Value::Bool(ord != Ordering::Less)),
    // Note: Short-circuiting is handled elsewhere.
    BinaryOp::And => Ok(Value::Bool(lhs.as_bool() && rhs.as_bool())),
    BinaryOp::Or => Ok(Value::Bool(lhs.as_bool() || rhs.as_bool())),
    BinaryOp::Is => {
      let check = do_type_check(bootstrapping, lhs, rhs)?;
      Ok(Value::Bool(check))
    }
    BinaryOp::IsNot => {
      let check = do_type_check(bootstrapping, lhs, rhs)?;
      Ok(Value::Bool(!check))
    }
    BinaryOp::In => {
      let check = do_elem_check(lhs, rhs)?;
      Ok(Value::Bool(check))
    }
    BinaryOp::NotIn => {
      let check = do_elem_check(lhs, rhs)?;
      Ok(Value::Bool(!check))
    }
    BinaryOp::Pow | BinaryOp::LShift | BinaryOp::RShift | BinaryOp::BitAnd | BinaryOp::BitOr | BinaryOp::BitXor => {
      // Don't think I need it
      unimplemented!()
    }
  }
}

fn do_type_check(bootstrapping: &BootstrappedTypes, lhs: Value, rhs: Value) -> Result<bool, EvalError> {
  let Value::ClassRef(rhs) = rhs else {
    return Err(EvalError::type_error("in", "class", rhs));
  };
  let Some(lhs_class) = lhs.get_class(bootstrapping) else {
    return Ok(false);
  };
  Ok(lhs_class.supertypes().any(|ty| Arc::ptr_eq(&ty, &rhs)))
}

fn do_elem_check(lhs: Value, rhs: Value) -> Result<bool, EvalError> {
  if let Value::String(rhs) = &rhs {
    let lhs = expect_string("in", &lhs)?;
    Ok(rhs.contains(&lhs))
  } else {
    Ok(rhs.try_iter()?.any(|elem| elem == lhs))
  }
}

pub fn expect_int(function_name: &str, value: &Value) -> Result<i64, EvalError> {
  match value {
    Value::Int(n) => Ok(*n),
    value => Err(EvalError::type_error(function_name, "integer", value.to_owned())),
  }
}

pub fn expect_int_loosely(function_name: &str, value: &Value) -> Result<i64, EvalError> {
  match value {
    Value::Int(n) => Ok(*n),
    Value::Float(n) => Ok(n.floor() as i64),
    value => Err(EvalError::type_error(function_name, "integer", value.to_owned())),
  }
}

/// Expect a float, but coerce integers as well.
pub fn expect_float_loosely(function_name: &str, value: &Value) -> Result<f64, EvalError> {
  match value {
    Value::Float(n) => Ok(**n),
    Value::Int(n) => Ok(*n as f64),
    value => Err(EvalError::type_error(function_name, "number", value.to_owned())),
  }
}

pub fn expect_bool(function_name: &str, value: &Value) -> Result<bool, EvalError> {
  match value {
    Value::Bool(b) => Ok(*b),
    value => Err(EvalError::type_error(function_name, "Boolean", value.to_owned())),
  }
}

pub fn expect_array<'v>(function_name: &str, value: &'v Value) -> Result<&'v RefCell<Vec<Value>>, EvalError> {
  match value {
    Value::ArrayRef(arr) => Ok(arr),
    value => Err(EvalError::type_error(function_name, "array", value.to_owned())),
  }
}

pub fn expect_dict<'v>(function_name: &str, value: &'v Value) -> Result<&'v RefCell<OrderMap<HashKey, Value>>, EvalError> {
  match value {
    Value::DictRef(d) => Ok(d),
    value => Err(EvalError::type_error(function_name, "dictionary", value.to_owned())),
  }
}

pub fn expect_string<'v>(function_name: &str, value: &'v Value) -> Result<&'v str, EvalError> {
  match value {
    Value::String(s) => Ok(&s),
    value => Err(EvalError::type_error(function_name, "string", value.to_owned())),
  }
}

fn promote_binary_nums<F1, F2>(op: &impl Display, lhs: Value, rhs: Value, on_integers: F1, on_floats: F2) -> Result<Value, EvalError>
where F1: FnOnce(i64, i64) -> Result<i64, EvalError>,
      F2: FnOnce(f64, f64) -> Result<f64, EvalError> {
  match (lhs, rhs) {
    (Value::Int(lhs), Value::Int(rhs)) => on_integers(lhs, rhs).map(Value::Int),
    (Value::Float(lhs), Value::Int(rhs)) => on_floats(*lhs, rhs as f64).map(Value::float),
    (Value::Int(lhs), Value::Float(rhs)) => on_floats(lhs as f64, *rhs).map(Value::float),
    (Value::Float(lhs), Value::Float(rhs)) => on_floats(*lhs, *rhs).map(Value::float),
    (lhs, rhs) => Err(EvalError::type_error(op.to_string(), "numbers", Value::new_array(vec![lhs, rhs]))),
  }
}

pub fn do_comparison_op(lhs: &Value, rhs: &Value) -> Result<Ordering, EvalError> {
  match (lhs, rhs) {
    (Value::Int(lhs), Value::Int(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Float(lhs), Value::Float(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Int(lhs), Value::Float(rhs)) => Ok(OrderedFloat(*lhs as f64).cmp(&rhs)),
    (Value::Float(lhs), Value::Int(rhs)) => Ok(lhs.cmp(&OrderedFloat(*rhs as f64))),
    (Value::String(lhs), Value::String(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Bool(lhs), Value::Bool(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Null, Value::Null) => Ok(Ordering::Equal),
    (Value::ArrayRef(_lhs), Value::ArrayRef(_rhs)) => {
      // I hope I don't need this one :(
      unimplemented!()
    }
    (lhs, rhs) => Err(EvalError::type_error("(comparison operator)", "comparable values", Value::new_array(vec![lhs.to_owned(), rhs.to_owned()]))),
  }
}

fn do_array_concat(lhs: Value, rhs: Value) -> Result<Value, EvalError> {
  let lhs = expect_array("+", &lhs)?;
  let rhs = expect_array("+", &rhs)?;
  let mut out = lhs.borrow().clone();
  out.extend(rhs.borrow().clone());
  Ok(Value::new_array(out))
}
