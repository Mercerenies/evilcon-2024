
use crate::ast::decl::FunctionDecl;
use crate::ast::identifier::Identifier;
use super::eval::EvaluatorState;
use super::class::Class;
use super::error::{EvalError, ExpectedArity, ControlFlow};
use super::value::Value;

use thiserror::Error;

use std::sync::Arc;
use std::fmt::{Formatter, Debug};
use std::ops::{Index, IndexMut};

#[derive(Debug, Clone)]
pub enum Method {
  /// Method defined in GDScript code.
  GdMethod(Arc<FunctionDecl>),
  /// Method written in Rust.
  RustMethod(RustMethod),
}

/// A method together with a reference to the class from which it
/// came.
#[derive(Debug, Clone)]
pub struct ScopedMethod {
  pub method: Method,
  pub owning_class: Option<Arc<Class>>,
}

#[derive(Clone)]
pub struct RustMethod {
  pub name: Identifier,
  pub is_static: bool,
  pub body: Arc<dyn Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + Send + Sync>,
}

#[derive(Debug, Clone)]
pub struct MethodArgs(pub Vec<Value>);

#[derive(Debug, Clone, Error)]
#[error("Wrong arity")]
pub struct TryFromMethodArgsError;

impl Method {
  pub fn name(&self) -> &Identifier {
    match self {
      Method::GdMethod(decl) => &decl.name,
      Method::RustMethod(m) => &m.name,
    }
  }

  pub fn rust_method(name: impl Into<Identifier>,
                     body: impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + Send + Sync + 'static) -> Method {
    Method::RustMethod(RustMethod {
      name: name.into(),
      is_static: false,
      body: Arc::new(body),
    })
  }

  pub fn rust_static_method(name: impl Into<Identifier>,
                            body: impl Fn(&mut EvaluatorState, MethodArgs) -> Result<Value, EvalError> + Send + Sync + 'static) -> Method {
    Method::RustMethod(RustMethod {
      name: name.into(),
      is_static: true,
      body: Arc::new(body),
    })
  }

  pub fn constructor_method() -> Method {
    fn body(state: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
      let Value::ClassRef(class) = state.self_instance() else {
        return Err(EvalError::type_error("class", state.self_instance().clone()));
      };
      let new_inst = Value::new_object(Arc::clone(class));
      for var in class.instance_vars() {
        // HACK: The scope of this evaluation is absolutely and
        // completely wrong. I hope I only use this for constants and
        // things for which scope doesn't matter.
        new_inst.set_value(&var.name.0, state.eval_expr(&var.initial_value)?, state.superglobal_state())?;
      }
      if let Ok(init_method) = class.get_func("_init") {
        state.call_function_prim(init_method.owning_class, &init_method.method, Box::new(new_inst.clone()), args)?;
      }
      Ok(new_inst)
    }
    Self::rust_static_method("new", body)
  }

  pub fn is_static(&self) -> bool {
    match self {
      Method::GdMethod(m) => m.is_static,
      Method::RustMethod(m) => m.is_static,
    }
  }

  pub fn noop() -> Method {
    fn body(_: &mut EvaluatorState, _: MethodArgs) -> Result<Value, EvalError> {
      Ok(Value::Null)
    }
    Self::rust_method("noop", body)
  }

  pub fn static_noop() -> Method {
    fn body(_: &mut EvaluatorState, _: MethodArgs) -> Result<Value, EvalError> {
      Ok(Value::Null)
    }
    Self::rust_static_method("noop", body)
  }

  pub fn unimplemented_stub(error_msg: &str) -> Method {
    let error_msg = error_msg.to_owned();
    let body = move |_: &mut EvaluatorState, _: MethodArgs| {
      Err(EvalError::UnimplementedMethod(error_msg.clone()))
    };
    Self::rust_method("unimplemented_stub", body)
  }

  /// Calls this method in the given context. The context should
  /// already be configured for the correct scope and will not be
  /// augmented for the method.
  ///
  /// Generally, outside callers should prefer
  /// [`EvaluatorState::call_function_on`] or a similar function,
  /// which does the appropriate scoping setup and then delegates to
  /// this method.
  pub fn call(&self, call_context: &mut EvaluatorState, args: MethodArgs) -> Result<Value, EvalError> {
    match self {
      Method::GdMethod(method) => {
        call_context.bind_arguments(method.name.as_ref(), args.0, method.params.clone())?;
        let result = call_context.eval_body(&method.body);
        ControlFlow::expect_return_or_null(result)
      }
      Method::RustMethod(method) => {
        (method.body)(call_context, args)
      }
    }
  }

  pub fn with_tracing<F>(self, tracing_function: F) -> Self
  where F: Fn(&EvaluatorState, &MethodArgs) + Send + Sync + 'static {
    Method::RustMethod(RustMethod {
      name: self.name().clone(),
      is_static: self.is_static(),
      body: Arc::new(move |state, args| {
        tracing_function(state, &args);
        self.call(state, args)
      }),
    })
  }

  pub fn scoped(self, owning_class: Option<Arc<Class>>) -> ScopedMethod {
    ScopedMethod {
      method: self,
      owning_class,
    }
  }
}

impl MethodArgs {
  pub const EMPTY: MethodArgs = MethodArgs(Vec::new());

  pub fn is_empty(&self) -> bool {
    self.0.is_empty()
  }

  pub fn len(&self) -> usize {
    self.0.len()
  }

  pub fn expect_one_arg(self, function_name: &str) -> Result<Value, EvalError> {
    self.expect_arity(1, function_name)?;
    let [arg] = self.try_into().unwrap();
    Ok(arg)
  }

  pub fn expect_two_args(self, function_name: &str) -> Result<(Value, Value), EvalError> {
    self.expect_arity(2, function_name)?;
    let [a, b] = self.try_into().unwrap();
    Ok((a, b))
  }

  pub fn expect_three_args(self, function_name: &str) -> Result<(Value, Value, Value), EvalError> {
    self.expect_arity(3, function_name)?;
    let [a, b, c] = self.try_into().unwrap();
    Ok((a, b, c))
  }

  pub fn expect_arity(&self, arity: usize, function_name: &str) -> Result<(), EvalError> {
    if self.0.len() != arity {
      Err(EvalError::WrongArity {
        function: function_name.to_owned(),
        expected: ExpectedArity::Exactly(arity),
        actual: self.0.len(),
      })
    } else {
      Ok(())
    }
  }

  pub fn expect_arity_within(&self, min_arity: usize, max_arity: usize, function_name: &str) -> Result<(), EvalError> {
    if (min_arity..=max_arity).contains(&self.0.len()) {
      Ok(())
    } else {
      Err(EvalError::WrongArity {
        function: function_name.to_owned(),
        expected: ExpectedArity::between(min_arity, max_arity),
        actual: self.0.len(),
      })
    }
  }
}

impl<const N: usize> TryFrom<MethodArgs> for [Value; N] {
  type Error = TryFromMethodArgsError;

  fn try_from(args: MethodArgs) -> Result<Self, Self::Error> {
    args.0.try_into().map_err(|_| TryFromMethodArgsError)
  }
}

impl Debug for RustMethod {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    f.debug_struct("RustMethod")
      .field("name", &self.name)
      .field("body", &"<fn>")
      .finish()
  }
}

impl Index<usize> for MethodArgs {
  type Output = Value;

  fn index(&self, index: usize) -> &Self::Output {
    &self.0[index]
  }
}

impl IndexMut<usize> for MethodArgs {
  fn index_mut(&mut self, index: usize) -> &mut Self::Output {
    &mut self.0[index]
  }
}
