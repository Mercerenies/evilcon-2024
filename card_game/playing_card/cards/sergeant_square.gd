extends MinionCardType


func get_id() -> int:
    return 7


func get_title() -> String:
    return "Sergeant Square"


func get_text() -> String:
    return "[i]A veteran soldier in the Icosaking's army. His resilience is unmatched among his peers.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 5


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.SHAPE]


func get_rarity() -> int:
    return Rarity.COMMON
