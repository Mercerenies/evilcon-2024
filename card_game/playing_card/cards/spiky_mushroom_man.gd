extends MinionCardType


func get_id() -> int:
    return 3


func get_title() -> String:
    return "Spiky Mushroom Man"


func get_text() -> String:
    return "A cute little mushroom with a spiky helmet. They say the helmet improves morale."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 3


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.FUNGUS]


func get_rarity() -> int:
    return Rarity.UNCOMMON
