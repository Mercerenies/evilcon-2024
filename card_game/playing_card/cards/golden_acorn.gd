extends MinionCardType


func get_id() -> int:
    return 14


func get_title() -> String:
    return "Golden Acorn"


func get_text() -> String:
    return "An extremely rare variant of the Corny Acorn. His jokes have the power to stop, and subsequently start, wars."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 20


func get_star_cost() -> int:
    return 8


func get_base_level() -> int:
    return 8


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.FUNGUS]


func get_rarity() -> int:
    return Rarity.RARE
