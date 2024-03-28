extends MinionCardType


func get_id() -> int:
    return 18


func get_title() -> String:
    return "Baby Clown"


func get_text() -> String:
    return "[i]A very small number of babies are born with the unusual genetic defect of makeup and a red button nose.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 44


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN]


func get_rarity() -> int:
    return Rarity.COMMON
