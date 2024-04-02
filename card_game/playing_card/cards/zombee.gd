extends MinionCardType


func get_id() -> int:
    return 62


func get_title() -> String:
    return "Zombee"


func get_text() -> String:
    return "[i]A bee infected with a parasitic fungus. The cost of eternal life.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 105


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.UNDEAD, Archetype.BEE]


func get_rarity() -> int:
    return Rarity.COMMON
