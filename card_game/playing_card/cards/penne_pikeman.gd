extends MinionCardType


func get_id() -> int:
    return 20


func get_title() -> String:
    return "Penne Pikeman"


func get_text() -> String:
    return "Nobody knows how he manages to hold the pike. Few have survived seeing it though."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 36


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.PASTA]


func get_rarity() -> int:
    return Rarity.COMMON
