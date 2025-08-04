
//! A game code consists of a random seed (for ChaCha8) and a card
//! game environment (i.e. the two players' decks). Game codes can be
//! serialized and deserialized to base64 for easy logging and
//! reproducibility.

use super::{CardId, CardGameEnv, DECK_SIZE};

use base64::Engine;
use base64::prelude::BASE64_STANDARD;
use thiserror::Error;

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum SerializeError {
  #[error("Bad deck size")]
  BadDeckSize,
}

#[derive(Debug, Clone, Error)]
#[non_exhaustive]
pub enum DeserializeError {
  #[error("{0}")]
  Base64DecodeError(#[from] base64::DecodeError),
  #[error("Expected zero byte at beginning")]
  InvalidVersionByte,
  #[error("Bad input length")]
  BadInputLength,
}

pub fn serialize_game_code(seed: u64, env: &CardGameEnv) -> Result<String, SerializeError> {
  // Note: This currently works for IDs up to 255. We're (as of
  // writing this on 8/3/25) at 194 right now, so it's not impossible
  // that we exceed 255 at some point. This function shall panic if it
  // encounters an ID above 255, in order to catch that as soon as
  // possible if it happens.
  if env.bottom_deck.len() != DECK_SIZE || env.top_deck.len() != DECK_SIZE {
    return Err(SerializeError::BadDeckSize);
  }
  let mut bytes = Vec::with_capacity(48);
  bytes.push(0u8); // Version code, always zero currently
  bytes.extend(seed.to_be_bytes());
  for card_id in &env.bottom_deck {
    assert!((0..=255).contains(&card_id.0), "Card ID {} is out of range", card_id.0);
    bytes.push(card_id.0 as u8);
  }
  for card_id in &env.top_deck {
    assert!((0..=255).contains(&card_id.0), "Card ID {} is out of range", card_id.0);
    bytes.push(card_id.0 as u8);
  }
  Ok(BASE64_STANDARD.encode(bytes))
}

pub fn deserialize_game_code(s: &str) -> Result<(u64, CardGameEnv), DeserializeError> {
  let bytes = BASE64_STANDARD.decode(s)?;
  if bytes.len() != 49 {
    return Err(DeserializeError::BadInputLength);
  }
  if bytes[0] != 0 {
    return Err(DeserializeError::InvalidVersionByte);
  }
  let seed = u64::from_be_bytes(bytes[1..9].try_into().unwrap());
  let bottom_deck = bytes[9..29].iter().map(|x| CardId(*x as i64)).collect();
  let top_deck = bytes[29..49].iter().map(|x| CardId(*x as i64)).collect();
  Ok((seed, CardGameEnv { bottom_deck, top_deck }))
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_roundtrip_game_code() {
    let example_seed = 123456u64;
    let bottom_deck = (0..20).map(|x| CardId(x)).collect();
    let top_deck = (51..71).map(|x| CardId(x)).collect();
    let input_env = CardGameEnv { bottom_deck, top_deck };
    let b64_str = serialize_game_code(example_seed, &input_env).unwrap();
    let (out_seed, out_env) = deserialize_game_code(&b64_str).unwrap();
    assert_eq!(example_seed, out_seed);
    assert_eq!(input_env, out_env);
  }
}
