extends MinionCardType


func get_id() -> int:
    return 112


func get_title() -> String:
    return "Fanciful Fairy"


func get_text() -> String:
    return "[i]She hasn't gotten her wings yet, but if you believe hard enough, maybe she will.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 126


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON]


func get_rarity() -> int:
    return Rarity.COMMON
