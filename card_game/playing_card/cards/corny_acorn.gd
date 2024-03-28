extends MinionCardType


func get_id() -> int:
    return 13


func get_title() -> String:
    return "Corny Acorn"


func get_text() -> String:
    return "[i]His corny jokes will crack you right open. Right before he cracks your skull.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 19


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.FUNGUS]


func get_rarity() -> int:
    return Rarity.COMMON
