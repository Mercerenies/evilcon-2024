extends MinionCardType


func get_id() -> int:
    return 134


func get_title() -> String:
    return "Agaric Turtle"


func get_text() -> String:
    return "[i]This poor turtle has mushrooms growing out of its back. It's a miracle that the critter is even still alive.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 145


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.TURTLE, Archetype.NATURE]


func get_rarity() -> int:
    return Rarity.COMMON
