extends MinionCardType


func get_id() -> int:
    return 6


func get_title() -> String:
    return "Triangle Trooper"


func get_text() -> String:
    return "One of the Icosaking's footsoldiers. They're untrained, but don't underestimate their strength in numbers."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 4


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.SHAPE]


func get_rarity() -> int:
    return Rarity.COMMON
