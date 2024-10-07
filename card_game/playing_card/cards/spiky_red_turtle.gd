extends MinionCardType


func get_id() -> int:
    return 110


func get_title() -> String:
    return "Spiky Red Turtle"


func get_text() -> String:
    return "[i]The perfect blend of intelligence and spikiness. Good luck getting him to go into his shell.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 116


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.UNCOMMON
