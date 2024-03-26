extends MinionCardType


func get_id() -> int:
    return 24


func get_title() -> String:
    return "Contractor"


func get_text() -> String:
    return "He's cheaper than a regular employee, and you don't have to cover his dental plan. It's win-win!"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 34


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.UNCOMMON
