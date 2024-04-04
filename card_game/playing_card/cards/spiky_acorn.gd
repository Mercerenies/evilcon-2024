extends MinionCardType


func get_id() -> int:
    return 66


func get_title() -> String:
    return "Spiky Acorn"


func get_text() -> String:
    return "[i]He only knows one joke, and it's the sound of his spikes as they make contact with their victim.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 101


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NATURE]


func get_rarity() -> int:
    return Rarity.COMMON
