extends MinionCardType


func get_id() -> int:
    return 150


func get_title() -> String:
    return "Berry"


func get_text() -> String:
    return "When Berry expires, gain 4 EP immediately."


func get_picture_index() -> int:
    return 156


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    await CardGameApi.highlight_card(playing_field, this_card)
    await Stats.add_evil_points(playing_field, this_card.owner, 4)
