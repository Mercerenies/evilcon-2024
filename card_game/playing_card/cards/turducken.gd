extends MinionCardType


func get_id() -> int:
    return 102


func get_title() -> String:
    return "Turducken"


func get_text() -> String:
    return "[i]The ultimate fusion of the finest birds in the land. Very few have witnessed the Turducken at its fullest strength.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 119


func get_star_cost() -> int:
    return 3


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.FARM]


func get_rarity() -> int:
    return Rarity.RARE
