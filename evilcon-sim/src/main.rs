
use evilcon_sim::parser::read_from_string;

use tree_sitter::Parser;
use tree_sitter_gdscript::LANGUAGE;

use std::env;
use std::fs::File;
use std::io::Read;

fn main() -> anyhow::Result<()> {
  let mut parser = Parser::new();
  parser.set_language(&LANGUAGE.into())?;

  let source_file = env::args().nth(1)
    .ok_or_else(|| anyhow::anyhow!("No source file provided"))?;
  let mut source_file = File::open(&source_file)?;
  let mut source_code = String::new();
  source_file.read_to_string(&mut source_code)?;

  let parsed = read_from_string(&source_code)?;
  println!("Parsed: {:?}", parsed);

  Ok(())
}
