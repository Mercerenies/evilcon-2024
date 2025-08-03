
//! Top-level loader for GDScript files.

use crate::ast::identifier::{ResourcePath, Identifier};
use crate::ast::file::{SourceFile, ExtendsClause};
use crate::parser::read_from_string;
use crate::parser::error::ParseError;
use crate::interpreter::eval::SuperglobalState;
use crate::interpreter::value::SimpleValue;
use crate::interpreter::error::EvalError;
use crate::interpreter::class::ClassBuilder;
use crate::interpreter::mocking;
use crate::interpreter::mocking::codex::{CodexDataFile, CodexLoadError};

use thiserror::Error;
use glob::glob;
use petgraph::algo;
use petgraph::graph::DiGraph;

use std::path::{Path, PathBuf};
use std::sync::LazyLock;
use std::fs::read_to_string;
use std::fmt::{self, Formatter, Debug};
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
  files: HashMap<ResourcePath, LoadedFile>,
  class_names: HashMap<Identifier, ResourcePath>,
}

struct LoadedFile {
  source_file: SourceFile,
  augmentation: Option<Box<dyn FnOnce(ClassBuilder) -> ClassBuilder + 'static>>,
}

#[derive(Debug, Error)]
pub enum LoadError {
  #[error("Parse error: {0}")]
  ParseError(#[from] ParseError),
  #[error("IO error: {0}")]
  IOError(#[from] io::Error),
}

#[derive(Clone, Debug, Error)]
pub enum DependencyError {
  #[error("Could not find named class {0}")]
  NoSuchNamedClass(Identifier),
  #[error("Could not find class by path {0}")]
  NoSuchClassByPath(ResourcePath),
}

#[derive(Debug, Error)]
pub enum BuildError {
  #[error("{0}")]
  DependencyError(#[from] DependencyError),
  #[error("{0}")]
  EvalError(#[from] EvalError),
  #[error("Cycle in dependency graph")]
  DependencyCycle,
  #[error("{0}")]
  CodexLoadError(#[from] CodexLoadError),
}

/// Result of [`GdScriptLoader::resolve_extends_clause`].
enum ExtendedClass<'a> {
  /// A loaded file, recognized by this loader.
  LoadedFile(&'a ResourcePath),
  /// A bootstrapped or mocked file that is already loaded into the
  /// core engine.
  ExistingFile,
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
    tracing::debug!("Loading file {}...", path.display());

    let file_contents = read_to_string(&path)?;
    let file = read_from_string(&file_contents)?;
    let path = normalize_path(&path)?;

    if let Some(class_name) = &file.class_name {
      self.class_names.insert(class_name.clone(), path.clone());
    }

    self.files.insert(path, LoadedFile {
      source_file: file,
      augmentation: None,
    });

    Ok(())
  }

  pub fn load_file_augmented<F>(&mut self, path: impl AsRef<Path>, augmentation: F) -> Result<(), LoadError>
  where F: FnOnce(ClassBuilder) -> ClassBuilder + 'static {
    let path = path.as_ref();
    tracing::debug!("Loading file {}...", path.display());

    let file_contents = read_to_string(&path)?;
    let file = read_from_string(&file_contents)?;
    let path = normalize_path(&path)?;

    if let Some(class_name) = &file.class_name {
      self.class_names.insert(class_name.clone(), path.clone());
    }

    self.files.insert(path, LoadedFile {
      source_file: file,
      augmentation: Some(Box::new(augmentation)),
    });

    Ok(())
  }

  pub fn load_all_files(&mut self, glob_str: &str) -> Result<(), LoadError> {
    for entry in glob(glob_str).expect("Could not read glob pattern") {
      match entry {
        Ok(path) => self.load_file(path)?,
        Err(e) => tracing::error!("Error during glob operation: {:?}", e),
      }
    }
    Ok(())
  }

  pub fn get(&self, path: &ResourcePath) -> Option<&SourceFile> {
    self.files.get(path).map(|file| &file.source_file)
  }

  pub fn get_by_class_name(&self, class_name: &Identifier) -> Option<&SourceFile> {
    let path = self.class_names.get(class_name)?;
    Some(self.get(path).expect("Could not find class name in files"))
  }

  pub fn build(mut self) -> Result<SuperglobalState, BuildError> {
    let mut superglobals = SuperglobalState::new();
    mocking::bind_mocked_classes(&mut superglobals);
    mocking::bind_mocked_constants(&mut superglobals);
    mocking::bind_mocked_methods(&mut superglobals);

    let codex_gd = CodexDataFile::read_from_default_file()?;
    codex_gd.bind_gd_class(&mut superglobals);

    let dependency_graph = self.build_dependency_graph(&superglobals)?;
    let top_sort = algo::toposort(&dependency_graph, None)
      .map_err(|_| BuildError::DependencyCycle)?;
    for res_path in top_sort.into_iter().rev() {
      let res_path = &dependency_graph[res_path];
      let file = self.files.remove(res_path).expect("Could not find file in files");
      let augmentation = file.augmentation.unwrap_or_else(|| Box::new(|b| b));
      superglobals.load_file_with(res_path.to_owned(), file.source_file, augmentation)?;
    }
    Ok(superglobals)
  }

  fn build_dependency_graph(&self, superglobals: &SuperglobalState) -> Result<DiGraph<ResourcePath, ()>, DependencyError> {
    let mut graph = DiGraph::new();

    let mut node_indices = HashMap::new();
    for path in self.files.keys() {
      node_indices.insert(path, graph.add_node(path.to_owned()));
    }
    for (path, file) in self.files.iter() {
      match self.resolve_extends_clause(superglobals, &file.source_file.extends_clause_or_default())? {
        ExtendedClass::ExistingFile => {
          // Dependency is already loaded; no need to represent it in
          // the graph.
        }
        ExtendedClass::LoadedFile(class_path) => {
          graph.add_edge(node_indices[path], node_indices[class_path], ());
        }
      }
    }

    Ok(graph)
  }

  fn resolve_extends_clause(&self, superglobals: &SuperglobalState, clause: &ExtendsClause) -> Result<ExtendedClass, DependencyError> {
    resolve_extends_clause_in_superglobals(superglobals, clause)
      .or_else(|| self.resolve_extends_clause_in_known_files(clause))
      .ok_or_else(|| no_such_class(clause))
  }

  fn resolve_extends_clause_in_known_files(&self, clause: &ExtendsClause) -> Option<ExtendedClass> {
    match clause {
      ExtendsClause::Id(class_name) => {
        self.class_names.get(class_name)
          .map(|class_path| ExtendedClass::LoadedFile(class_path))
      }
      ExtendsClause::Path(class_path) => {
        self.files.get_key_value(class_path.as_ref())
          .map(|(k, _)| ExtendedClass::LoadedFile(k))
      }
    }
  }
}

impl Debug for LoadedFile {
  fn fmt(&self, f: &mut Formatter) -> fmt::Result {
    f.debug_struct("LoadedFile")
      .field("source_file", &self.source_file)
      .field("augmentation", &self.augmentation.as_ref().map(|_| "<augmentation>"))
      .finish()
  }
}

pub fn normalize_path(path: impl AsRef<Path>) -> io::Result<ResourcePath> {
  let absolute_path = path.as_ref().canonicalize()?;
  let rel_path = absolute_path.strip_prefix(&*GODOT_PROJECT_ROOT)
    .map_err(|_| io::Error::new(io::ErrorKind::NotFound, "Could not normalize path"))?;
  let rel_path = rel_path.to_string_lossy();
  Ok(ResourcePath::new(format!("res://{rel_path}")))
}

fn resolve_extends_clause_in_superglobals(superglobals: &SuperglobalState, clause: &ExtendsClause) -> Option<ExtendedClass<'static>> {
  match clause {
    ExtendsClause::Id(class_name) => {
      let var = superglobals.get_var(class_name)?;
      if matches!(var, SimpleValue::ClassRef(_)) {
        Some(ExtendedClass::ExistingFile)
      } else {
        None
      }
    }
    ExtendsClause::Path(class_path) => {
      superglobals.get_file(class_path.as_ref())
        .map(|_| ExtendedClass::ExistingFile)
    }
  }
}

fn no_such_class(clause: &ExtendsClause) -> DependencyError {
  match clause {
    ExtendsClause::Id(class_name) => DependencyError::NoSuchNamedClass(class_name.clone()),
    ExtendsClause::Path(class_path) => DependencyError::NoSuchClassByPath(ResourcePath::new(class_path.clone())),
  }
}
