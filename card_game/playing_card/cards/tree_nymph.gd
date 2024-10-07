extends MinionCardType


func get_id() -> int:
    return 111


func get_title() -> String:
    return "Tree Nymph"


func get_text() -> String:
    return "[i]She speaks for the trees, for the trees have no tongue.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 125


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.DEMON]


func get_rarity() -> int:
    return Rarity.COMMON
