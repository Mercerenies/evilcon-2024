extends MinionCardType


func get_id() -> int:
    return 26


func get_title() -> String:
    return "Toddler Clown"


func get_text() -> String:
    return "[i]And you think the terrible twos are bad with a regular toddler...[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 45


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.CLOWN]


func get_rarity() -> int:
    return Rarity.COMMON
