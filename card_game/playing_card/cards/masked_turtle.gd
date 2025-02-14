extends MinionCardType


func get_id() -> int:
    return 38


func get_title() -> String:
    return "Masked Turtle"


func get_text() -> String:
    return "Masked Turtle is immune to enemy card effects."


func get_picture_index() -> int:
    return 26


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.NINJA, Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.COMMON


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        super.do_influence_check(playing_field, target_card, source_card, silently)
    )


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    return (
        super.ai_get_score(playing_field, player, priorities) +
        priorities.of(LookaheadPriorities.IMMUNITY) * ai_get_expected_remaining_score(playing_field, null)
    )
