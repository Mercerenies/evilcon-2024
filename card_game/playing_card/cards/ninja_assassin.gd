extends MinionCardType


func get_id() -> int:
    return 37


func get_title() -> String:
    return "Ninja Assassin"


func get_text() -> String:
    return "Immune to enemy card effects."


func get_picture_index() -> int:
    return 15


func get_star_cost() -> int:
    return 3


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.NINJA]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func do_influence_check(playing_field, target_card, source_card) -> bool:
    return (
        await CardEffects.do_ninja_influence_check(playing_field, target_card, source_card) and
        await super.do_influence_check(playing_field, target_card, source_card)
    )
