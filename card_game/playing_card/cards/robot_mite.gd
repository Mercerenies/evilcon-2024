extends MinionCardType


func get_id() -> int:
    return 15


func get_title() -> String:
    return "Robot Mite"


func get_text() -> String:
    return "[i]A cute little robot bug, powered by several raspberries. Or something like that.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 21


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.COMMON
