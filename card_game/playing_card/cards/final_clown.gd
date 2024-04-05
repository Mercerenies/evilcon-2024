extends MinionCardType


func get_id() -> int:
    return 74


func get_title() -> String:
    return "Final Clown"


func get_text() -> String:
    return "[i]The life of a clown is a hard one, so anyone who survives to this ripe old age must be dangerous or crazy. Or both.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 111


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN]


func get_rarity() -> int:
    return Rarity.UNCOMMON
