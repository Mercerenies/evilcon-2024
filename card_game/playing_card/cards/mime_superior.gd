extends MinionCardType


func get_id() -> int:
    return 73


func get_title() -> String:
    return "Mime Superior"


func get_text() -> String:
    return "[i]A high-ranking member of the Order of the Mimes. He is sworn to absolute secrecy about the order's nature, which is easy given that he never speaks.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 112


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN]


func get_rarity() -> int:
    return Rarity.UNCOMMON
