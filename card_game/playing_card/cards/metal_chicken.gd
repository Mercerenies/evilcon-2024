extends MinionCardType


func get_id() -> int:
    return 158


func get_title() -> String:
    return "Metal Chicken"


func get_text() -> String:
    return "[i]We would've called the chicken a robot, but some big scary lawyers told us we couldn't do that.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 181


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT, Archetype.FARM]


func get_rarity() -> int:
    return Rarity.COMMON
