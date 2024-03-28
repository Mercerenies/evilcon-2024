extends MinionCardType


func get_id() -> int:
    return 16


func get_title() -> String:
    return "Meatball Man"


func get_text() -> String:
    return "[i]That red hue is the marinara sauce dripping from his last victims.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 29


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.PASTA]


func get_rarity() -> int:
    return Rarity.COMMON
