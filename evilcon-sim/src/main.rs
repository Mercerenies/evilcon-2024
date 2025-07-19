
use evilcon_sim::driver;

fn main() -> anyhow::Result<()> {
  driver::load_all_files()?;

  Ok(())
}
