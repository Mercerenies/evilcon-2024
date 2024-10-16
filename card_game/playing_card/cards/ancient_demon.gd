extends MinionCardType


func get_id() -> int:
    return 133


func get_title() -> String:
    return "Ancient Demon"


func get_text() -> String:
    return "[i]After thousands of years of service to the Devil, a demon may be granted a small amount of his power.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 124


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON]


func get_rarity() -> int:
    return Rarity.UNCOMMON
