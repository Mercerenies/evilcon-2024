extends MinionCardType


func get_id() -> int:
    return 30


func get_title() -> String:
    return "Hired Ninja"


func get_text() -> String:
    return "Hired Ninja is immune to enemy card effects."


func get_picture_index() -> int:
    return 14


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NINJA]


func get_rarity() -> int:
    return Rarity.COMMON


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        await CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        await super.do_influence_check(playing_field, target_card, source_card, silently)
    )


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    return (
        super.ai_get_score(playing_field, player, priorities) +
        priorities.of(LookaheadPriorities.IMMUNITY)
    )
