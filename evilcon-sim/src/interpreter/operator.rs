
use crate::ast::expr::operator::{BinaryOp, UnaryOp};
use super::value::Value;
use super::error::EvalError;

use ordered_float::OrderedFloat;

use std::cmp::Ordering;
use std::rc::Rc;

pub fn eval_unary_op(op: UnaryOp, value: Value) -> Result<Value, EvalError> {
  match op {
    UnaryOp::Not => Ok(Value::Bool(!value.as_bool())),
    UnaryOp::Pos => Ok(value),
    UnaryOp::Neg => {
      match value {
        Value::Int(n) => Ok(Value::Int(-n)),
        Value::Float(f) => Ok(Value::Float(-f)),
        value => Err(EvalError::type_error("number", value)),
      }
    }
    UnaryOp::Compl => {
      // Don't think I need it
      unimplemented!()
    }
  }
}

pub fn eval_binary_op(lhs: Value, op: BinaryOp, rhs: Value) -> Result<Value, EvalError> {
  match op {
    BinaryOp::Add => promote_binary_nums(lhs, rhs, |lhs, rhs| Ok(lhs + rhs), |lhs, rhs| Ok(lhs + rhs)),
    BinaryOp::Sub => promote_binary_nums(lhs, rhs, |lhs, rhs| Ok(lhs - rhs), |lhs, rhs| Ok(lhs - rhs)),
    BinaryOp::Mul => promote_binary_nums(lhs, rhs, |lhs, rhs| Ok(lhs * rhs), |lhs, rhs| Ok(lhs * rhs)),
    BinaryOp::Div => promote_binary_nums(lhs, rhs, |lhs, rhs| Ok(lhs / rhs), |lhs, rhs| Ok(lhs / rhs)), // Note: Integer division on ints
    BinaryOp::Mod => {
      let lhs = expect_int(lhs)?;
      let rhs = expect_int(rhs)?;
      Ok(Value::Int(lhs % rhs))
    }
    BinaryOp::Eq => Ok(Value::Bool(lhs == rhs)),
    BinaryOp::Ne => Ok(Value::Bool(lhs != rhs)),
    BinaryOp::Lt => do_comparison_op(lhs, rhs).map(|ord| Value::Bool(ord == Ordering::Less)),
    BinaryOp::Le => do_comparison_op(lhs, rhs).map(|ord| Value::Bool(ord != Ordering::Greater)),
    BinaryOp::Gt => do_comparison_op(lhs, rhs).map(|ord| Value::Bool(ord == Ordering::Greater)),
    BinaryOp::Ge => do_comparison_op(lhs, rhs).map(|ord| Value::Bool(ord != Ordering::Less)),
    // Note: Short-circuiting is handled elsewhere.
    BinaryOp::And => Ok(Value::Bool(lhs.as_bool() && rhs.as_bool())),
    BinaryOp::Or => Ok(Value::Bool(lhs.as_bool() || rhs.as_bool())),
    BinaryOp::Is => {
      let check = do_type_check(lhs, rhs)?;
      Ok(Value::Bool(check))
    }
    BinaryOp::IsNot => {
      let check = do_type_check(lhs, rhs)?;
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

fn do_type_check(lhs: Value, rhs: Value) -> Result<bool, EvalError> {
  let Value::ClassRef(rhs) = rhs else {
    return Err(EvalError::type_error("class", rhs));
  };
  let Some(lhs_class) = lhs.get_class() else {
    return Ok(false);
  };
  Ok(lhs_class.supertypes().any(|ty| Rc::ptr_eq(&ty, &rhs)))
}

fn do_elem_check(lhs: Value, rhs: Value) -> Result<bool, EvalError> {
  Ok(rhs.try_iter()?.any(|elem| elem == lhs))
}

fn expect_int(value: Value) -> Result<i64, EvalError> {
  match value {
    Value::Int(n) => Ok(n),
    value => Err(EvalError::type_error("number", value)),
  }
}

fn promote_binary_nums<F1, F2>(lhs: Value, rhs: Value, on_integers: F1, on_floats: F2) -> Result<Value, EvalError>
where F1: FnOnce(i64, i64) -> Result<i64, EvalError>,
      F2: FnOnce(f64, f64) -> Result<f64, EvalError> {
  match (lhs, rhs) {
    (Value::Int(lhs), Value::Int(rhs)) => on_integers(lhs, rhs).map(Value::Int),
    (Value::Float(lhs), Value::Int(rhs)) => on_floats(*lhs, rhs as f64).map(Value::float),
    (Value::Int(lhs), Value::Float(rhs)) => on_floats(lhs as f64, *rhs).map(Value::float),
    (Value::Float(lhs), Value::Float(rhs)) => on_floats(*lhs, *rhs).map(Value::float),
    (lhs, rhs) => Err(EvalError::type_error("numbers", Value::new_array(vec![lhs, rhs]))),
  }
}

fn do_comparison_op(lhs: Value, rhs: Value) -> Result<Ordering, EvalError> {
  match (lhs, rhs) {
    (Value::Int(lhs), Value::Int(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Float(lhs), Value::Float(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Int(lhs), Value::Float(rhs)) => Ok(OrderedFloat(lhs as f64).cmp(&rhs)),
    (Value::Float(lhs), Value::Int(rhs)) => Ok(lhs.cmp(&OrderedFloat(rhs as f64))),
    (Value::String(lhs), Value::String(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Bool(lhs), Value::Bool(rhs)) => Ok(lhs.cmp(&rhs)),
    (Value::Null, Value::Null) => Ok(Ordering::Equal),
    (Value::ArrayRef(_lhs), Value::ArrayRef(_rhs)) => {
      // I hope I don't need this one :(
      unimplemented!()
    }
    (lhs, rhs) => Err(EvalError::type_error("comparable values", Value::new_array(vec![lhs, rhs]))),
  }
}
