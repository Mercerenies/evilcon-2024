extends MinionCardType


func get_id() -> int:
    return 12


func get_title() -> String:
    return "Busy Bee"


func get_text() -> String:
    return "Busy bee buzzing blissfully between blooming blossoms."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 18


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.BEE]


func get_rarity() -> int:
    return Rarity.COMMON
