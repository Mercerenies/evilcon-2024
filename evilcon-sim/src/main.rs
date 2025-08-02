
use evilcon_sim::driver;
use evilcon_sim::cardgame::{GameEngine, CardId, CardGameEnv};

use rand_chacha::ChaCha8Rng;
use rand::SeedableRng;

use std::env;

fn main() -> anyhow::Result<()> {
  // Get a u64 random seed from cmd line args, or a random one if none
  // is provided.
  let rand_seed = if let Some(seed) = env::args().nth(1) {
    seed.parse::<u64>()?
  } else {
    rand::random::<u64>()
  };
  println!("Running with random seed: {}", rand_seed);
  let random_generator = ChaCha8Rng::seed_from_u64(rand_seed);

  let superglobals = driver::load_all_files()?;
  let engine = GameEngine::new(superglobals);
  let env = CardGameEnv {
    bottom_deck: sample_deck(),
    top_deck: sample_deck(),
  };
  let outcome = engine.play_game(&env, random_generator)?;
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
