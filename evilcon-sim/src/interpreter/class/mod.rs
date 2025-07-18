
pub mod constant;

use crate::ast::identifier::Identifier;
use crate::ast::file::{SourceFile, ExtendsClause};
use crate::ast::expr::{Expr, Literal};
use crate::ast::stmt::VarStmt;
use crate::ast::decl::{Decl, FunctionDecl};
use super::method::Method;
use super::error::EvalError;
use super::eval::SuperglobalState;
use super::value::{Value, NoSuchFunc};
use constant::LazyConst;

use std::hash::{Hash, Hasher};
use std::rc::Rc;
use std::collections::HashMap;

/// A class written in Godot or mocked Rust-side.
#[derive(Debug, Clone)]
pub struct Class {
  pub name: Option<String>,
  pub parent: Option<Rc<Class>>,
  pub constants: Rc<HashMap<Identifier, LazyConst>>,
  pub instance_vars: Vec<InstanceVar>,
  pub methods: HashMap<Identifier, Method>,
}

#[derive(Debug, Clone)]
pub struct InstanceVar {
  pub name: Identifier,
  pub initial_value: Expr,
}

#[derive(Debug, Clone)]
pub struct ClassSupertypesIter {
  curr: Option<Rc<Class>>,
}

impl Class {
  pub fn load_from_file(superglobals: &mut SuperglobalState, file: SourceFile) -> Result<Self, EvalError> {
    let name = file.class_name;
    let parent = match file.extends_clause.unwrap_or_default() {
      ExtendsClause::Id(identifier) => {
        let value = superglobals.get_var(&identifier).ok_or_else(|| EvalError::UnknownClass(identifier.clone().into()))?;
        let Value::ClassRef(cls) = value else {
          return Err(EvalError::UnknownClass(identifier.into()));
        };
        cls.clone()
      }
      ExtendsClause::Path(path) => {
        superglobals.get_file(path.as_ref()).ok_or_else(|| EvalError::UnknownClass(path.into()))?
      }
    };
    let mut constants = HashMap::new();
    let mut instance_vars = Vec::new();
    let mut methods = HashMap::new();
    for decl in file.decls {
      match decl {
        Decl::Const { name, value } => {
          constants.insert(name, const_evaluator(*value));
        }
        Decl::Var(var_stmt) => {
          instance_vars.push(var_stmt.into());
        }
        Decl::Constructor(constructor) => {
          let func = FunctionDecl {
            name: Identifier::new("_init"),
            params: constructor.params,
            is_static: false,
            body: constructor.body,
          };
          methods.insert(Identifier::new("_init"), Method::GdMethod(Rc::new(func)));
        }
        Decl::Function(function) => {
          methods.insert(function.name.to_owned(), Method::GdMethod(Rc::new(function)));
        }
        Decl::Enum(enum_decl) => {
          let mut enum_values = HashMap::new();
          let mut prev = -1i64;
          for (name, value) in enum_decl.members {
            let curr_value = match value {
              None => prev + 1,
              Some(Expr::Literal(Literal::Int(i))) => i,
              Some(expr) => return Err(EvalError::InvalidEnumConstant(expr)),
            };
            enum_values.insert(name, curr_value);
            prev = curr_value;
          }
          let enum_type = Value::EnumType(enum_values);
          constants.insert(enum_decl.name, LazyConst::resolved(enum_type));
        }
        Decl::InnerClass(name, class_body) => {
          let file = SourceFile {
            extends_clause: None,
            class_name: None,
            decls: class_body,
          };
          let inner_class = Self::load_from_file(superglobals, file)?;
          constants.insert(name, LazyConst::resolved(Value::ClassRef(Rc::new(inner_class))));
        }
      };
    }
    Ok(Class {
      name: name.map(|name| name.into()),
      parent: Some(parent),
      constants: Rc::new(constants),
      instance_vars,
      methods,
    })
  }

  pub fn get_func(&self, name: &str) -> Result<&Method, NoSuchFunc> {
    let mut curr = Some(self);
    while let Some(cls) = curr {
      if let Some(method) = cls.methods.get(name) {
        return Ok(method);
      }
      curr = cls.parent.as_deref();
    }
    Err(NoSuchFunc(name.into()))
  }

  pub fn supertypes(self: Rc<Class>) -> ClassSupertypesIter {
    ClassSupertypesIter { curr: Some(self) }
  }
}

impl Iterator for ClassSupertypesIter {
  type Item = Rc<Class>;

  fn next(&mut self) -> Option<Self::Item> {
    if let Some(cls) = self.curr.clone() {
      self.curr = cls.parent.clone();
      Some(cls)
    } else {
      None
    }
  }
}

fn const_evaluator(value: Expr) -> LazyConst {
  LazyConst::new(move |state| {
    state.eval_expr(&value)
  })
}

impl PartialEq for Class {
  fn eq(&self, other: &Self) -> bool {
    self.name == other.name
  }
}

impl Eq for Class {}

impl Hash for Class {
  fn hash<H: Hasher>(&self, state: &mut H) {
    self.name.hash(state)
  }
}

impl From<VarStmt> for InstanceVar {
  fn from(stmt: VarStmt) -> Self {
    Self {
      name: stmt.name,
      initial_value: *stmt.initial_value.unwrap_or_else(|| Box::new(Expr::from(Literal::Null))),
    }
  }
}
