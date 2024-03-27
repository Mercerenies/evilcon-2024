extends MinionCardType


func get_id() -> int:
    return 25


func get_title() -> String:
    return "Middle Manager"


func get_text() -> String:
    return "[i]He's never off the clock. He even carries his work phone into his dreams.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 35


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.UNCOMMON
