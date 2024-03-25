extends MinionCardType


func get_id() -> int:
    return 10


func get_title() -> String:
    return "Captain Circle"


func get_text() -> String:
    return "A high-ranking military officer. Often regarded as the most logical and strategic soldiers in the Icosaking's army."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 8


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.SHAPE]


func get_rarity() -> int:
    return Rarity.UNCOMMON
