
use evilcon_sim::driver;
use evilcon_sim::cardgame::{GameEngine, CardId, CardGameEnv};

fn main() -> anyhow::Result<()> {
  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);
  let env = CardGameEnv {
    bottom_deck: sample_deck(),
    top_deck: sample_deck(),
  };
  let outcome = engine.play_game(&env)?;
  println!("Winner: {}", outcome);
  Ok(())
}

fn sample_deck() -> Vec<CardId> {
  vec![
    CardId(10), CardId(17), CardId(99), CardId(101), CardId(4),
    CardId(1), CardId(1), CardId(1), CardId(81), CardId(82),
    CardId(83), CardId(91), CardId(140), CardId(141), CardId(17),
    CardId(83), CardId(91), CardId(140), CardId(141), CardId(17),
  ]
}
