extends MinionCardType


func get_id() -> int:
    return 67


func get_title() -> String:
    return "Cordyceps"


func get_text() -> String:
    return "[i]A deadly fungus known for infecting and replacing the body of its victims.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 103


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NATURE]


func get_rarity() -> int:
    return Rarity.UNCOMMON
