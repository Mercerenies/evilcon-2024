extends MinionCardType


func get_id() -> int:
    return 1


func get_title() -> String:
    return "Mushroom Man"


func get_text() -> String:
    return "An adorable little mushroom. He doesn't look too threatening."


func is_text_flavor() -> bool:
    return true


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.FUNGUS]


func get_rarity() -> int:
    return Rarity.COMMON
