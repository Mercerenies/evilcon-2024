
//! Operator names and types

use strum_macros::Display;
use thiserror::Error;

use std::str::FromStr;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash, Display)]
pub enum UnaryOp {
  #[strum(serialize = "!")]
  Not,
  #[strum(serialize = "+")]
  Pos,
  #[strum(serialize = "-")]
  Neg,
  #[strum(serialize = "~")]
  Compl,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash, Display)]
pub enum BinaryOp {
  #[strum(serialize = "+")]
  Add,
  #[strum(serialize = "-")]
  Sub,
  #[strum(serialize = "*")]
  Mul,
  #[strum(serialize = "/")]
  Div,
  #[strum(serialize = "%")]
  Mod,
  #[strum(serialize = "**")]
  Pow,
  #[strum(serialize = "<<")]
  LShift,
  #[strum(serialize = ">>")]
  RShift,
  #[strum(serialize = "&")]
  BitAnd,
  #[strum(serialize = "|")]
  BitOr,
  #[strum(serialize = "^")]
  BitXor,
  #[strum(serialize = "==")]
  Eq,
  #[strum(serialize = "!=")]
  Ne,
  #[strum(serialize = "<")]
  Lt,
  #[strum(serialize = "<=")]
  Le,
  #[strum(serialize = ">")]
  Gt,
  #[strum(serialize = ">=")]
  Ge,
  #[strum(serialize = "&&")]
  And,
  #[strum(serialize = "||")]
  Or,
  #[strum(serialize = "is")]
  Is,
  #[strum(serialize = "is not")]
  IsNot,
  #[strum(serialize = "in")]
  In,
  #[strum(serialize = "not in")]
  NotIn,
}

#[derive(Default, Debug, Copy, Clone, PartialEq, Eq, Hash, Display)]
pub enum AssignOp {
  #[default]
  #[strum(serialize = "=")]
  Eq,
  #[strum(serialize = "+=")]
  AddEq,
  #[strum(serialize = "-=")]
  SubEq,
  #[strum(serialize = "*=")]
  MulEq,
  #[strum(serialize = "/=")]
  DivEq,
  #[strum(serialize = "%=")]
  ModEq,
  #[strum(serialize = "**=")]
  PowEq,
  #[strum(serialize = "&=")]
  BitAndEq,
  #[strum(serialize = "|=")]
  BitOrEq,
  #[strum(serialize = "^=")]
  BitXorEq,
  #[strum(serialize = "<<=")]
  LShiftEq,
  #[strum(serialize = ">>=")]
  RShiftEq,
}

#[derive(Debug, Clone, Error)]
#[error("Failed to parse operator {0}")]
pub struct OpFromStrError(String);

impl AssignOp {
  pub fn as_binary(self) -> Option<BinaryOp> {
    match self {
      AssignOp::Eq => None,
      AssignOp::AddEq => Some(BinaryOp::Add),
      AssignOp::SubEq => Some(BinaryOp::Sub),
      AssignOp::MulEq => Some(BinaryOp::Mul),
      AssignOp::DivEq => Some(BinaryOp::Div),
      AssignOp::ModEq => Some(BinaryOp::Mod),
      AssignOp::PowEq => Some(BinaryOp::Pow),
      AssignOp::BitAndEq => Some(BinaryOp::BitAnd),
      AssignOp::BitOrEq => Some(BinaryOp::BitOr),
      AssignOp::BitXorEq => Some(BinaryOp::BitXor),
      AssignOp::LShiftEq => Some(BinaryOp::LShift),
      AssignOp::RShiftEq => Some(BinaryOp::RShift),
    }
  }
}

/// Note: This is not an exact round-trip for `Display`. Some
/// operators have multiple names (such as `not` and `!`). `FromStr`
/// will parse both but will normalize to one representation.
impl FromStr for UnaryOp {
  type Err = OpFromStrError;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    Ok(match s {
      "!" | "not" => UnaryOp::Not,
      "+" => UnaryOp::Pos,
      "-" => UnaryOp::Neg,
      "~" => UnaryOp::Compl,
      _ => return Err(OpFromStrError(s.to_owned())),
    })
  }
}

/// Note: This is not an exact round-trip for `Display`. Some
/// operators have multiple names (such as `and` and `&&`). `FromStr`
/// will parse both but will normalize to one representation.
impl FromStr for BinaryOp {
  type Err = OpFromStrError;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    Ok(match s {
      "+" => BinaryOp::Add,
      "-" => BinaryOp::Sub,
      "*" => BinaryOp::Mul,
      "/" => BinaryOp::Div,
      "%" => BinaryOp::Mod,
      "**" => BinaryOp::Pow,
      "<<" => BinaryOp::LShift,
      ">>" => BinaryOp::RShift,
      "&" => BinaryOp::BitAnd,
      "|" => BinaryOp::BitOr,
      "^" => BinaryOp::BitXor,
      "==" => BinaryOp::Eq,
      "!=" => BinaryOp::Ne,
      "<" => BinaryOp::Lt,
      "<=" => BinaryOp::Le,
      ">" => BinaryOp::Gt,
      ">=" => BinaryOp::Ge,
      "&&" | "and" => BinaryOp::And,
      "||" | "or" => BinaryOp::Or,
      "is" => BinaryOp::Is,
      "is not" => BinaryOp::IsNot,
      "in" => BinaryOp::In,
      "not in" => BinaryOp::NotIn,
      _ => return Err(OpFromStrError(s.to_owned())),
    })
  }
}

impl FromStr for AssignOp {
  type Err = OpFromStrError;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    Ok(match s {
      "=" => AssignOp::Eq,
      "+=" => AssignOp::AddEq,
      "-=" => AssignOp::SubEq,
      "*=" => AssignOp::MulEq,
      "/=" => AssignOp::DivEq,
      "%=" => AssignOp::ModEq,
      "**=" => AssignOp::PowEq,
      "&=" => AssignOp::BitAndEq,
      "|=" => AssignOp::BitOrEq,
      "^=" => AssignOp::BitXorEq,
      "<<=" => AssignOp::LShiftEq,
      ">>=" => AssignOp::RShiftEq,
      _ => return Err(OpFromStrError(s.to_owned())),
    })
  }
}
