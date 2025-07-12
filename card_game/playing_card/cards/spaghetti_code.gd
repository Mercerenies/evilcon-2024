extends MinionCardType


func get_id() -> int:
    return 189


func get_title() -> String:
    return "Spaghetti Code"


func get_text() -> String:
    return "[i]Sometimes the messiest code is the most beautiful.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 202


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.PASTA, Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.COMMON
