extends MinionCardType


func get_id() -> int:
    return 32


func get_title() -> String:
    return "Spiky Turtle"


func get_text() -> String:
    return "[i]They briefly considered breeding turtles with a spiky shell, but that was deemed too unrealistic. So instead they just attached spikes to all of his other body parts.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 95


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.COMMON
