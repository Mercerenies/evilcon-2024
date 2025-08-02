
use evilcon_sim::driver;

fn main() -> anyhow::Result<()> {
  driver::load_all_files()?;

  //test_driver()?;

  Ok(())
}

/*
fn test_driver() -> anyhow::Result<()> {
  let mut loader = loader::GdScriptLoader::new();
  loader.load_file(concat!(env!("CARGO_MANIFEST_DIR"), "/tmp.gd"))?;
  eprintln!("Loaded test file");
  let superglobals = Arc::new(loader.build()?);
  let interpreter = eval::EvaluatorState::new(superglobals);
  let test_class = interpreter.get_file("res://evilcon-sim/tmp.gd")
    .ok_or_else(|| anyhow::anyhow!("Could not find tmp.gd"))?;
  let result = interpreter.call_function_on_class(&test_class, "test", Vec::new())?;
  eprintln!("Output: {}", result);
  eprintln!("Debug code: {:?}", result);
  Ok(())
}
*/
