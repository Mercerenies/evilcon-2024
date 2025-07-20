
//! String-handling functions at the AST level.

use crate::util;

use strum_macros::{Display, VariantArray};
use strum::VariantArray;
use thiserror::Error;

use std::sync::LazyLock;
use std::str::FromStr;
use std::fmt::{self, Display, Formatter};

/// String literal within a Godot source file.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct GdString {
  pub string_type: StringType,
  pub contents: String,
}

/// Type of string literal.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct StringType {
  pub prefix: StringPrefix,
  /// If true, the string uses three copies of the quote character in
  /// the starting and ending delimiter. If false, the string uses one
  /// copy.
  pub triple_quoted: bool,
  pub quote_type: char,
}

/// Starting character, indicating the type of string.
#[derive(Debug, Clone, Copy, Display, VariantArray, PartialEq, Eq, Hash)]
pub enum StringPrefix {
  #[strum(serialize = "")]
  None,
  #[strum(serialize = "r")]
  Raw,
  #[strum(serialize = "&")]
  StringName,
  #[strum(serialize = "^")]
  NodePath,
}

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum StringLitFromStrError {
  #[error("Missing or invalid opening delimiter")]
  InvalidOpeningDelim,
  #[error("Missing or invalid closing delimiter")]
  InvalidClosingDelim,
  #[error("{0}")]
  InvalidEscapeSequence(#[from] InvalidEscapeSequence),
}

#[derive(Debug, Clone, Error)]
#[error("Invalid escape sequence")]
pub struct InvalidEscapeSequence {
  _priv: (),
}

/// All string types supported by Godot. This array is ordered such
/// that string types whose starting delimiter is a prefix of another
/// are sorted after those that extend them.
pub static ALL_STRING_TYPES: LazyLock<Vec<StringType>> = LazyLock::new(|| {
  let mut all = Vec::with_capacity(16);
  for triple_quoted in &[true, false] {
    for quote_type in &['\'', '"'] {
      for prefix in StringPrefix::VARIANTS {
        all.push(StringType {
          triple_quoted: *triple_quoted,
          quote_type: *quote_type,
          prefix: *prefix,
        })
      }
    }
  }
  all
});

impl GdString {
  pub fn new(string_type: StringType, contents: impl Into<String>) -> Self {
    Self {
      string_type,
      contents: contents.into(),
    }
  }

  pub fn simple(contents: impl Into<String>) -> Self {
    Self::new(StringType { prefix: StringPrefix::None, triple_quoted: false, quote_type: '"' }, contents)
  }
}

impl StringType {
  pub fn start_delim(&self) -> String {
    format!("{}{}", self.prefix, self.end_delim())
  }

  pub fn end_delim(&self) -> String {
    let s = String::from(self.quote_type);
    if self.triple_quoted {
      s.repeat(3)
    } else {
      s
    }
  }

  pub fn admits_escape_sequences(&self) -> bool {
    self.prefix != StringPrefix::Raw
  }
}

fn interpret_escape_char<I>(iter: &mut I) -> Result<char, InvalidEscapeSequence>
where I: Iterator<Item = char> {
  let Some(ch) = iter.next() else {
    return Err(InvalidEscapeSequence { _priv: () });
  };
  match ch {
    'n' => Ok('\n'),
    't' => Ok('\t'),
    'r' => Ok('\r'),
    'a' => Ok('\x07'),
    'b' => Ok('\x08'),
    'f' => Ok('\x0C'),
    'v' => Ok('\x0B'),
    '"' => Ok('"'),
    '\'' => Ok('\''),
    '\\' => Ok('\\'),
    'u' => read_unicode_escape(iter, 4),
    'U' => read_unicode_escape(iter, 6),
    _ => Err(InvalidEscapeSequence { _priv: () }),
  }
}

fn read_unicode_escape<I>(iter: &mut I, digit_count: usize) -> Result<char, InvalidEscapeSequence>
where I: Iterator<Item = char> {
  fn read<I>(iter: &mut I, digit_count: usize) -> Option<char>
  where I: Iterator<Item = char> {
    let first_n = util::take_n(iter, digit_count).into_iter().collect::<String>();
    if first_n.chars().count() < digit_count {
      return None;
    }
    let hex = u32::from_str_radix(&first_n, 16).ok()?;
    char::from_u32(hex)
  }
  read(iter, digit_count).ok_or(InvalidEscapeSequence { _priv: () })
}

impl From<GdString> for String {
  fn from(gd_string: GdString) -> String {
    gd_string.contents
  }
}

impl AsRef<str> for GdString {
  fn as_ref(&self) -> &str {
    &self.contents
  }
}

impl FromStr for GdString {
  type Err = StringLitFromStrError;

  fn from_str(s: &str) -> Result<Self, StringLitFromStrError> {
    let (string_prefix, s) = read_string_prefix(s);
    let (triple_quoted, quote_type, s) = read_delimiter(s).ok_or(StringLitFromStrError::InvalidOpeningDelim)?;
    let delim_length = if triple_quoted { 3 } else { 1 };
    let string_contents = &s[0..s.len() - delim_length];
    let mut string_contents = string_contents.chars();
    let mut parsed_contents = String::new();
    while let Some(ch) = string_contents.next() {
      if ch == '\\' {
        parsed_contents.push(interpret_escape_char(&mut string_contents)?);
      } else {
        parsed_contents.push(ch);
      }
    }
    Ok(GdString::new(StringType { prefix: string_prefix, triple_quoted, quote_type }, parsed_contents))
  }
}

impl Display for GdString {
  fn fmt(&self, f: &mut Formatter) -> fmt::Result {
    write!(f, "{}", self.contents)
  }
}

fn read_string_prefix(s: &str) -> (StringPrefix, &str) {
  match s.chars().next() {
    Some('r') => (StringPrefix::Raw, &s[1..]),
    Some('&') => (StringPrefix::StringName, &s[1..]),
    Some('^') => (StringPrefix::NodePath, &s[1..]),
    _ => (StringPrefix::None, s),
  }
}

fn read_delimiter(s: &str) -> Option<(bool, char, &str)> {
  // Special cases: empty strings will incorrectly parse as
  // badly-triple-quoted strings if we don't do them here.
  if s == "\"\"" {
    return Some((false, '"', &s[1..]));
  }
  if s == "''" {
    return Some((false, '\'', &s[1..]));
  }

  let mut iter = s.chars();
  let ch = iter.next()?;
  if ch != '"' && ch != '\'' {
    return None;
  }
  assert!(ch.len_utf8() == 1); // Note: For the rest of this function, we can assume this.
  if iter.next()? == ch {
    // Triple-quoted
    if iter.next()? != ch {
      return None; // Badly triple-quoted
    }
    Some((true, ch, &s[3..]))
  } else {
    // Single-quoted
    Some((false, ch, &s[1..]))
  }
}
