
use crate::loader::GdScriptLoader;
use crate::ast::identifier::Identifier;
use crate::interpreter::eval::SuperglobalState;
use crate::interpreter::value::Value;
use crate::interpreter::class::Class;

use std::sync::Arc;

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
  "../card_game/playing_card/card_meta.gd",
  "../card_game/playing_card/archetype.gd",
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

  let mut superglobals = loader.build()?;
  eprintln!("Created interpreter environment.");

  eprintln!("Performing surgery ...");
  do_surgery(&mut superglobals)?;
  eprintln!("Surgery complete.");

  Ok(superglobals)
}

/// Some precise manipulation of a few specific classes.
fn do_surgery(superglobals: &mut SuperglobalState) -> anyhow::Result<()> {
  fn get_inner_class(cls: &Class, name: &str) -> anyhow::Result<Arc<Class>> {
    let inner_value = cls.get_constant(name)
      .ok_or_else(|| anyhow::anyhow!("Could not find name '{name}' in class"))?
      .get_if_initialized()
      .map_err(|_poisoned_err| anyhow::anyhow!("Somehow, a class constant is poisoned"))?
      .ok_or_else(|| anyhow::anyhow!("Class '{name}' is a nontrivial lazy const"))?;
    if let Value::ClassRef(inner_class) = inner_value {
      Ok(Arc::clone(inner_class))
    } else {
      anyhow::bail!("Class '{name}' is not a class reference");
    }
  }

  // Place Query.Q and Query.QueryManager at the top-level global
  // scope.
  let Some(Value::ClassRef(query_class)) = superglobals.get_var("Query") else {
    anyhow::bail!("Could not find Query class");
  };
  let q_class = get_inner_class(query_class, "Q")?;
  let query_manager_class = get_inner_class(query_class, "QueryManager")?;
  superglobals.bind_class(Identifier::new("Query"), q_class);
  superglobals.bind_class(Identifier::new("QueryManager"), query_manager_class);
  Ok(())
}
