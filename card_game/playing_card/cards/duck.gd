extends MinionCardType


func get_id() -> int:
    return 101


func get_title() -> String:
    return "Duck"


func get_text() -> String:
    return "[i]The most famous of the aquatic birds. Who keeps recruiting all of these random animals as minions?[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 118


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.FARM]


func get_rarity() -> int:
    return Rarity.COMMON
