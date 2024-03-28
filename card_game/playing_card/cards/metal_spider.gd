extends MinionCardType


func get_id() -> int:
    return 36


func get_title() -> String:
    return "Metal Spider"


func get_text() -> String:
    return "[i]Spiders are a natural phobia of many people, so why not build an army of robotic ones?[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 58


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.COMMON
