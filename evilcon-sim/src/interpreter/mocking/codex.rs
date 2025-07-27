
//! The `PlayingCardCodex` mocked class. In principle, this class
//! should be readable in GDScript. But the tree-sitter parser chokes
//! on nested identifiers in `match` clauses, so for now we just
//! generate this file here.
//!
//! This one is a bit unique, in that it requires a YAML file as input
//! to determine the playing cards and their IDs. The YAML file comes
//! from the same automated Ruby task that generates
//! `playing_card_codex.gd`.
//!
//! Since the binding properties for this class are different, this
//! class is **not** bound by default in
//! [`bind_mocked_classes`](super::bind_mocked_classes) and must be
//! bound separately.

use crate::interpreter::class::Class;
use crate::interpreter::class::constant::LazyConst;
use crate::interpreter::eval::{SuperglobalState, EvaluatorState};
use crate::interpreter::method::MethodArgs;
use crate::interpreter::value::Value;
use crate::interpreter::error::EvalError;
use crate::interpreter::operator::expect_int_loosely;
use crate::ast::identifier::{Identifier, ResourcePath};

use serde::{Deserialize, Serialize};
use thiserror::Error;

use std::io::{self, Read};
use std::fs::File;
use std::sync::Arc;
use std::collections::HashMap;

pub const DEFAULT_YAML_PATH: &str =
  concat!(env!("CARGO_MANIFEST_DIR"), "/../codex_metadata.yaml");

pub const CODEX_GD_FILE_PATH: &str =
  "res://card_game/playing_card/playing_card_codex.gd";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodexDataFile {
  pub max_id: i64,
  pub cards: Vec<CodexEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodexEntry {
  pub id: i64,
  pub name: String,
  pub path: String,
}

/// Small error type for [`CodexDataFile::read_from_default_file`].
#[derive(Debug, Error)]
pub enum CodexLoadError {
  #[error("{0}")]
  IoError(#[from] io::Error),
  #[error("{0}")]
  YmlError(#[from] serde_yml::Error),
}

impl CodexDataFile {
  pub fn read_from_file<R: Read>(reader: R) -> serde_yml::Result<Self> {
    serde_yml::from_reader(reader)
  }

  pub fn read_from_default_file() -> Result<Self, CodexLoadError> {
    let file = File::open(DEFAULT_YAML_PATH)?;
    Ok(Self::read_from_file(file)?)
  }

  pub fn to_gd_class(&self) -> Class {
    let mut constants = HashMap::new();
    constants.insert(Identifier::new("ID"), LazyConst::resolved(self.id_enum()));

    let mut methods = HashMap::new();

    /////

    Class {
      name: Some(String::from("PlayingCardCodex")),
      parent: None,
      constants: Arc::new(constants),
      instance_vars: Vec::new(),
      methods,
    }
  }

  pub fn bind_gd_class(&self, superglobals: &mut SuperglobalState) {
    let cls = Arc::new(self.to_gd_class());
    superglobals.add_file(ResourcePath(CODEX_GD_FILE_PATH.to_owned()), Arc::clone(&cls));
    superglobals.bind_class(Identifier::new("PlayingCardCodex"), cls);
  }

  fn id_enum(&self) -> Value {
    let value_map = self.cards.iter()
      .map(|card| (Identifier::new(&card.name), card.id))
      .collect();
    Value::EnumType(value_map)
  }

  fn get_entity_script(&self, evaluator: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
    let id = expect_int_loosely(&args.expect_one_arg()?)?;
    let id = usize::try_from(id).map_err(|_| EvalError::domain_error("Card ID out of range"))?;
    todo!() /////
  }
}
