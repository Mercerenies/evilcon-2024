extends MinionCardType


func get_id() -> int:
    return 8


func get_title() -> String:
    return "Rhombus Ranger"


func get_text() -> String:
    return "A member of the Icosaking's archery division. They say he can hit a mirror crystal at 100 paces."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 6


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.SHAPE]


func get_rarity() -> int:
    return Rarity.COMMON
