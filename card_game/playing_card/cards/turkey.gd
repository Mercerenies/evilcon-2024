extends MinionCardType


func get_id() -> int:
    return 100


func get_title() -> String:
    return "Turkey"


func get_text() -> String:
    return "[i]For Thanksgiving, he enjoys a collection of seeds and fruits. You monster.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 117


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.FARM]


func get_rarity() -> int:
    return Rarity.COMMON
