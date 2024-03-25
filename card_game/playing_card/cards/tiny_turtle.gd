extends MinionCardType


func get_id() -> int:
    return 4


func get_title() -> String:
    return "Tiny Turtle"


func get_text() -> String:
    return "A little turtle who wouldn't hurt a fly. He doesn't work for money. He just wants a big hug."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 25


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.COMMON
