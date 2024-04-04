extends MinionCardType


func get_id() -> int:
    return 65


func get_title() -> String:
    return "Military Android"


func get_text() -> String:
    return "[i]The ultimate culmination of science, technology, and an unquenchable thirst for blood.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 108


func get_star_cost() -> int:
    return 8


func get_base_level() -> int:
    return 4


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.RARE
