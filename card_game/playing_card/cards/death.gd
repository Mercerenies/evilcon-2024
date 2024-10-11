extends MinionCardType


func get_id() -> int:
    return 116


func get_title() -> String:
    return "Death"


func get_text() -> String:
    return "Death has +2 Level if you control no other Minions."


func get_picture_index() -> int:
    return 139


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func get_level(playing_field, card) -> int:
    var starting_level = super.get_level(playing_field, card)
    var friendly_minion_count = playing_field.get_minion_strip(card.owner).cards().card_count()
    return starting_level + (2 if friendly_minion_count == 1 else 0)
