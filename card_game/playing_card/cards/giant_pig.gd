extends MinionCardType


func get_id() -> int:
    return 35


func get_title() -> String:
    return "Giant Pig"


func get_text() -> String:
    return "[i]A pig that was hit with a growth beam. The FDA has not commented on the safety or morality of this practice.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 40


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.FARM]


func get_rarity() -> int:
    return Rarity.UNCOMMON
