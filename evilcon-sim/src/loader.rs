
//! Top-level loader for GDScript files.

use crate::ast::identifier::{ResourcePath, Identifier};
use crate::ast::file::SourceFile;
use crate::parser::read_from_string;
use crate::parser::error::ParseError;

use thiserror::Error;
use glob::glob;

use std::path::{Path, PathBuf};
use std::sync::LazyLock;
use std::fs::read_to_string;
use std::collections::HashMap;
use std::io;

pub const GODOT_PROJECT_ROOT: LazyLock<PathBuf> = LazyLock::new(|| {
  let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
  manifest_dir.ancestors()
    .find(|ancestor| ancestor.join("project.godot").exists())
    .expect("Could not find Godot project root")
    .to_owned()
});

#[derive(Debug)]
pub struct GdScriptLoader {
  files: HashMap<ResourcePath, SourceFile>,
  class_names: HashMap<Identifier, ResourcePath>,
}

#[derive(Debug, Error)]
pub enum LoadError {
  #[error("Parse error: {0}")]
  ParseError(#[from] ParseError),
  #[error("IO error: {0}")]
  IOError(#[from] io::Error),
}

impl GdScriptLoader {
  pub fn new() -> GdScriptLoader {
    GdScriptLoader {
      files: HashMap::new(),
      class_names: HashMap::new(),
    }
  }

  pub fn load_file(&mut self, path: impl AsRef<Path>) -> Result<(), LoadError> {
    let path = path.as_ref();
    eprintln!("Loading file {}...", path.display());

    let file_contents = read_to_string(&path)?;
    let file = read_from_string(&file_contents)?;
    let path = normalize_path(&path)?;

    if let Some(class_name) = &file.class_name {
      self.class_names.insert(class_name.clone(), path.clone());
    }

    self.files.insert(path, file);

    Ok(())
  }

  pub fn load_all_files(&mut self, glob_str: &str) -> Result<(), LoadError> {
    for entry in glob(glob_str).expect("Could not read glob pattern") {
      match entry {
        Ok(path) => self.load_file(path)?,
        Err(e) => eprintln!("{:?}", e),
      }
    }
    Ok(())
  }

  pub fn get(&self, path: &ResourcePath) -> Option<&SourceFile> {
    self.files.get(path)
  }

  pub fn get_by_class_name(&self, class_name: &Identifier) -> Option<&SourceFile> {
    let path = self.class_names.get(class_name)?;
    Some(self.files.get(path).expect("Could not find class name in files"))
  }
}

pub fn normalize_path(path: impl AsRef<Path>) -> io::Result<ResourcePath> {
  let absolute_path = path.as_ref().canonicalize()?;
  let rel_path = absolute_path.strip_prefix(&*GODOT_PROJECT_ROOT)
    .map_err(|_| io::Error::new(io::ErrorKind::NotFound, "Could not normalize path"))?;
  Ok(ResourcePath::new(rel_path.to_string_lossy()))
}
