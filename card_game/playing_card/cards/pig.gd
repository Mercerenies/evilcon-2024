extends MinionCardType


func get_id() -> int:
    return 34


func get_title() -> String:
    return "Pig"


func get_text() -> String:
    return "[i]A classic, unmodified farm animal. Healthy and safe.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 39


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.FARM]


func get_rarity() -> int:
    return Rarity.UNCOMMON
