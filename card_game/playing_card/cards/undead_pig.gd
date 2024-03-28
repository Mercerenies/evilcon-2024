extends MinionCardType


func get_id() -> int:
    return 39


func get_title() -> String:
    return "Undead Pig"


func get_text() -> String:
    return "[i]A pig brought back to life via the ancient practice of necromancy.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 41


func get_star_cost() -> int:
    return 3


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.UNDEAD, Archetype.FARM]


func get_rarity() -> int:
    return Rarity.UNCOMMON
