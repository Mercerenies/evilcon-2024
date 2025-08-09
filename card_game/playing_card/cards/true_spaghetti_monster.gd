extends MinionCardType


func get_id() -> int:
    return 199


func get_title() -> String:
    return "True Spaghetti Monster"


func get_text() -> String:
    return "[i]The highest form of pasta being in existence. All pastakind strives to one day be assimilated into His Majesty.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 215


func get_star_cost() -> int:
    return 9


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.PASTA]


func get_rarity() -> int:
    return Rarity.RARE
