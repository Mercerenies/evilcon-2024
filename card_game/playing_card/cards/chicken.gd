extends MinionCardType


func get_id() -> int:
    return 33


func get_title() -> String:
    return "Chicken"


func get_text() -> String:
    return "[i]It's just a random chicken that some evil mastermind decided to send into battle. Most of them just wander off and look for seeds.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 30


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.FARM]


func get_rarity() -> int:
    return Rarity.COMMON
