extends MinionCardType


func get_id() -> int:
    return 11


func get_title() -> String:
    return "Ravioli Runt"


func get_text() -> String:
    return "[i]Calling him a \"runt\" is a good way to get kicked in the lasagna.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 28


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.PASTA]


func get_rarity() -> int:
    return Rarity.COMMON
