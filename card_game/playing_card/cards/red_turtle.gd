extends MinionCardType


func get_id() -> int:
    return 109


func get_title() -> String:
    return "Red Turtle"


func get_text() -> String:
    return "[i]The red turtles are smarter and less prone to walk off cliffsides than their green counterparts, which makes them better suited to, frankly, most tasks.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 115


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.COMMON
