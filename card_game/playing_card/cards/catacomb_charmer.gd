extends MinionCardType


func get_id() -> int:
    return 41


func get_title() -> String:
    return "Catacomb Charmer"


func get_text() -> String:
    return "[i]She was so obsessed with skeletons that she decided to become one herself.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 56


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.UNDEAD, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE
