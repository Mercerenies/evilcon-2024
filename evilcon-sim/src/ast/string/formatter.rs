
//! String formatters matching Godot's semantics.

use regex::Regex;
use thiserror::Error;

use std::cmp::Ordering;
use std::sync::LazyLock;
use std::fmt::Display;
use std::borrow::Cow;

const PERCENT_RE: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"%s").unwrap());

#[derive(Debug, Clone, Error)]
pub enum FormatterError {
  #[error("Too many format args")]
  TooManyFormatArgs,
  #[error("Not enough format args")]
  NotEnoughFormatArgs,
}

/// String formatter which fills in `%s` (and only `%s`) directives
/// with the values.
pub fn format_percent<'s, T>(format_str: &'s str, args: &[T]) -> Result<Cow<'s, str>, FormatterError>
where T: Display {
  let format_args_expected = PERCENT_RE.find_iter(format_str).count();
  match args.len().cmp(&format_args_expected) {
    Ordering::Greater => return Err(FormatterError::TooManyFormatArgs),
    Ordering::Less => return Err(FormatterError::NotEnoughFormatArgs),
    Ordering::Equal => {}
  };
  let mut args = args.iter();
  Ok(PERCENT_RE.replace_all(format_str, |_: &regex::Captures<'_>| {
    args.next().unwrap().to_string()
  }))
}
