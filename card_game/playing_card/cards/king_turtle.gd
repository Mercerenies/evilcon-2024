extends MinionCardType


func get_id() -> int:
    return 71


func get_title() -> String:
    return "King Turtle"


func get_text() -> String:
    return "[i]The undisputed ruler of turtle-kind, with a penchant for kidnapping princesses and fighting handymen.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 102


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.UNCOMMON
