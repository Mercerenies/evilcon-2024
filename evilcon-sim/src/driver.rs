
use crate::loader::GdScriptLoader;
use crate::interpreter::eval::SuperglobalState;

pub const GDSCRIPT_FILES: &[&str] = &[
  "../card_game/playing_field/event_logger.gd",
  "../card_game/playing_field/util/card_effects.gd",
  "../card_game/playing_field/util/card_game_phases.gd",
  "../card_game/playing_field/util/card_game_turn_transitions.gd",
  "../card_game/playing_field/util/query.gd",
  "../card_game/playing_field/util/stats_calculator.gd",
  "../card_game/playing_field/card_container/card_container.gd",
  "../card_game/playing_field/player_agent/player_agent.gd",
  "../card_game/playing_field/player_agent/lookahead_ai_agent/lookahead_ai_agent.gd",
  "../card_game/playing_field/player_agent/lookahead_ai_agent/lookahead_priorities.gd",
  "../card_game/playing_field/card_player.gd",
  "../util.gd",
  "../operator.gd",
  "../card_game/playing_card/playing_card_lists.gd",
  "../card_game/playing_card/card.gd",
];

pub const GDSCRIPT_GLOBS: &[&str] = &[
  "../card_game/playing_card/card_type/*.gd",
  "../card_game/playing_card/cards/*.gd",
];

pub fn load_all_files() -> anyhow::Result<SuperglobalState> {
  let mut loader = GdScriptLoader::new();
  for file in GDSCRIPT_FILES {
    loader.load_file(file)?;
  }
  for glob in GDSCRIPT_GLOBS {
    loader.load_all_files(glob)?;
  }
  eprintln!("Loaded all files.");
  let superglobals = loader.build()?;
  eprintln!("Created interpreter environment.");
  Ok(superglobals)
}
