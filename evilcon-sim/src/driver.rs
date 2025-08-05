
use crate::loader::GdScriptLoader;
use crate::ast::identifier::Identifier;
use crate::interpreter::eval::SuperglobalState;
use crate::interpreter::value::{Value, SimpleValue, ObjectInst};
use crate::interpreter::class::{Class, ClassBuilder};

use glob::glob;

use std::sync::Arc;

/// Files that are loaded according to the standard rules. Note that
/// some additional files are loaded below with custom augmentations
/// (mainly for debugging purposes).
const GDSCRIPT_FILES: &[&str] = &[
  "../card_game/playing_field/event_logger.gd",
  "../card_game/playing_field/card_player.gd",
  "../card_game/playing_field/log_events.gd",
  "../card_game/playing_field/util/card_effects.gd",
  "../card_game/playing_field/util/card_game_phases.gd",
  "../card_game/playing_field/util/query.gd",
  "../card_game/playing_field/util/stats_calculator.gd",
  "../card_game/playing_field/destination_transform.gd",
  "../card_game/playing_field/card_container/card_container.gd",
  "../card_game/playing_field/player_agent/player_agent.gd",
  "../card_game/playing_field/player_agent/lookahead_ai_agent/lookahead_ai_agent.gd",
  "../card_game/playing_field/player_agent/lookahead_ai_agent/lookahead_priorities.gd",
  "../util.gd",
  "../operator.gd",
  "../card_game/playing_card/playing_card_lists.gd",
  "../card_game/playing_card/card_meta.gd",
  "../card_game/playing_card/archetype.gd",
];

const GDSCRIPT_GLOBS: &[&str] = &[
  "../card_game/playing_card/card_type/*.gd",
];

pub fn load_all_files() -> anyhow::Result<SuperglobalState> {
  let mut loader = GdScriptLoader::new();
  for file in GDSCRIPT_FILES {
    let file = format!("{}/{}", env!("CARGO_MANIFEST_DIR"), file);
    loader.load_file(&file)?;
  }
  load_card_gd(&mut loader)?;
  load_card_game_api_gd(&mut loader)?;

  // Each individual card type loader and to_string
  {
    let glob_str = format!("{}/../card_game/playing_card/cards/*.gd", env!("CARGO_MANIFEST_DIR"));
    for entry in glob(&glob_str).expect("Could not read glob pattern") {
      match entry {
        Ok(path) => {
          let file_name = path.file_stem().unwrap().to_string_lossy().into_owned();
          loader.load_file_augmented(&path, with_custom_to_string(move |_| file_name.to_owned()))?;
        }
        Err(e) => tracing::error!("Error during glob: {:?}", e),
      }
    }
  }

  for glob in GDSCRIPT_GLOBS {
    let glob = format!("{}/{}", env!("CARGO_MANIFEST_DIR"), glob);
    loader.load_all_files(&glob)?;
  }
  tracing::info!("Loaded all files.");

  let mut superglobals = loader.build()?;
  tracing::info!("Created interpreter environment.");

  tracing::info!("Performing surgery ...");
  do_surgery(&mut superglobals)?;
  tracing::info!("Surgery complete.");

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
    if let SimpleValue::ClassRef(inner_class) = inner_value {
      Ok(Arc::clone(inner_class))
    } else {
      anyhow::bail!("Class '{name}' is not a class reference");
    }
  }

  // Place Query.Q and Query.QueryManager at the top-level global
  // scope.
  let Some(SimpleValue::ClassRef(query_class)) = superglobals.get_var("Query") else {
    anyhow::bail!("Could not find Query class");
  };
  let q_class = get_inner_class(query_class, "Q")?;
  let query_manager_class = get_inner_class(query_class, "QueryManager")?;
  superglobals.bind_class(Identifier::new("Q"), q_class);
  superglobals.bind_class(Identifier::new("QueryManager"), query_manager_class);
  Ok(())
}

fn with_custom_to_string(
  custom_to_string: impl Fn(&ObjectInst) -> String + Send + Sync + 'static,
) -> (impl FnOnce(ClassBuilder) -> ClassBuilder + 'static) {
  move |builder| {
    builder.custom_to_string(custom_to_string)
  }
}

fn load_card_gd(loader: &mut GdScriptLoader) -> anyhow::Result<()> {
  let file = format!("{}/../card_game/playing_card/card.gd", env!("CARGO_MANIFEST_DIR"));
  loader.load_file_augmented(&file, with_custom_to_string(|obj| {
    if let Some(card_type) = obj.dict_get("card_type") {
      format!("<object Card type: {}>", card_type)
    } else {
      String::from("<object Card>")
    }
  }))?;
  Ok(())
}

fn load_card_game_api_gd(loader: &mut GdScriptLoader) -> anyhow::Result<()> {
  // We add tracing to a TON of these functions, since they're the
  // central access point for things in the game moving about.
  let file = format!("{}/../card_game/playing_field/util/card_game_api.gd", env!("CARGO_MANIFEST_DIR"));
  loader.load_file_augmented(&file, |builder| {
    builder
      .modify_method("draw_cards", |method| method.with_tracing(|_, args| {
        match args.len() {
          2 => { // playing_field and player
            tracing::debug!(player=?args[1], "Attempt to draw 1 card(s)");
          }
          3 => {
            tracing::debug!(player=?args[1], "Attempt to draw {} card(s)", &args[2]);
          }
          _ => {
            tracing::error!("Bad arity to draw_cards");
          }
        }
      }))
      .modify_method("draw_specific_card", |method| method.with_tracing(|_, args| {
        if args.len() != 3 {
          tracing::error!("Bad arity to draw_specific_card");
          return;
        }
        tracing::debug!(player=?args[1], "Scry {} from deck", &args[2]);
      }))
      .modify_method("reshuffle_discard_pile", |method| method.with_tracing(|_, args| {
        if args.len() != 2 {
          tracing::error!("Bad arity to reshuffle_discard_pile");
          return;
        }
        tracing::debug!(player=?args[1], "Reshuffle discard pile");
      }))
      .modify_method("play_card_from_hand", |method| method.with_tracing(|_, args| {
        if args.len() != 3 {
          tracing::error!("Bad arity to play_card_from_hand");
          return;
        }
        tracing::debug!(player=?args[1], "Play {} from hand", &args[2]);
      }))
      .modify_method("resurrect_card", |method| method.with_tracing(|_, args| {
        if args.len() != 3 {
          tracing::error!("Bad arity to resurrect_card");
          return;
        }
        tracing::debug!(player=?args[1], "Resurrect {} from discard pile", &args[2]);
      }))
      .modify_method("play_card_from_deck", |method| method.with_tracing(|_, args| {
        if args.len() != 3 {
          tracing::error!("Bad arity to play_card_from_deck");
          return;
        }
        tracing::debug!(player=?args[1], "Play {} from deck", &args[2]);
      }))
      .modify_method("play_card_from_nowhere", |method| method.with_tracing(|_, args| {
        if args.len() < 3 { // This function accepts additional args that I don't care about
          tracing::error!("Bad arity to play_card_from_nowhere");
          return;
        }
        tracing::debug!(player=?args[1], "Play {} from nowhere (probably Mystery Box)", &args[2]);
      }))
      .modify_method("destroy_card", |method| method.with_tracing(|_, args| {
        if args.len() != 2 {
          tracing::error!("Bad arity to destroy_card");
          return;
        }
        let player = try_get_owner(&args[1]);
        tracing::debug!(player=player, "Destroy {}", &args[1]);
      }))
      .modify_method("discard_card", |method| method.with_tracing(|_, args| {
        if args.len() != 3 {
          tracing::error!("Bad arity to discard_card");
          return;
        }
        tracing::debug!(player=?args[1], "Discard {} from hand", &args[2]);
      }))
      .modify_method("move_card_from_discard_to_deck", |method| method.with_tracing(|_, args| {
        if args.len() != 3 {
          tracing::error!("Bad arity to move_card_from_discard_to_deck");
          return;
        }
        tracing::debug!(player=?args[1], "Move {} from discard to deck", &args[2]);
      }))
      .modify_method("create_card", |method| method.with_tracing(|_, args| {
        if args.len() < 3 { // Ignore optional is_token arg
          tracing::error!("Bad arity to create_card");
          return;
        }
        tracing::debug!(player=?args[1], "Create card {}", &args[2]);
      }))
      .modify_method("copy_card", |method| method.with_tracing(|_, args| {
        if args.len() < 3 { // Ignore optional is_token arg
          tracing::error!("Bad arity to copy_card");
          return;
        }
        tracing::debug!(player=?args[1], "Copy card {}", &args[2]);
      }))
      .modify_method("exile_card", |method| method.with_tracing(|_, args| {
        if args.len() != 2 {
          tracing::error!("Bad arity to exile_card");
          return;
        }
        let player = try_get_owner(&args[1]);
        tracing::debug!(player=player, "Exile {}", &args[1]);
      }))
  })?;
  Ok(())
}

/// Best-effort attempt to get the owner, for logging purposes. If
/// anything bad happens, returns a default value.
fn try_get_owner(card_value: &Value) -> String {
  fn try_get_owner_impl(card_value: &Value) -> Option<String> {
    let Value::ObjectRef(obj) = card_value else {
      return None;
    };
    let obj = obj.borrow();
    let Some(Value::String(owner)) = obj.dict_get("owner") else {
      return None;
    };
    Some(owner.to_owned())
  }
  try_get_owner_impl(card_value).unwrap_or_else(|| String::from("<unknown>"))
}
