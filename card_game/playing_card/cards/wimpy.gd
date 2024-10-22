extends MinionCardType


func get_id() -> int:
    return 160


func get_title() -> String:
    return "Wimpy"


func get_text() -> String:
    return "[i]Some kid who always gets picked on in school. What can you expect from a poor kid whose mother named him \"Wimpy\"?[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 179


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON
