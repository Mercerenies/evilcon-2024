extends MinionCardType


func get_id() -> int:
    return 5


func get_title() -> String:
    return "Zany Zombie"


func get_text() -> String:
    return "He's not unreasonable. I mean, no one's gonna eat your eyes."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 17


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.UNDEAD]


func get_rarity() -> int:
    return Rarity.COMMON
