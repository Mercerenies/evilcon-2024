extends MinionCardType


func get_id() -> int:
    return 64


func get_title() -> String:
    return "Ninja Master"


func get_text() -> String:
    return "Ninja Master is immune to enemy card effects."


func get_picture_index() -> int:
    return 107


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NINJA]


func get_rarity() -> int:
    return Rarity.RARE


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        await CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        await super.do_influence_check(playing_field, target_card, source_card, silently)
    )
