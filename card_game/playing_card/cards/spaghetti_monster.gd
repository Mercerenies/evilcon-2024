extends MinionCardType


func get_id() -> int:
    return 19


func get_title() -> String:
    return "Spaghetti Monster"


func get_text() -> String:
    return "[i]A strange being made of pure spaghetti. His mysterious aura has attracted something of a religious devotion.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 38


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.PASTA]


func get_rarity() -> int:
    return Rarity.UNCOMMON
