extends MinionCardType


func get_id() -> int:
    return 1


func get_title() -> String:
    return "Mushroom Man"


func get_text() -> String:
    return "[i]An adorable little mushroom. He doesn't look too threatening.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 1


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.NATURE]


func get_rarity() -> int:
    return Rarity.COMMON
