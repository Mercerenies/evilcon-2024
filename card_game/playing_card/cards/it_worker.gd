extends MinionCardType


func get_id() -> int:
    return 23


func get_title() -> String:
    return "IT Worker"


func get_text() -> String:
    return "Capable of solving any computer problem you've got. Just don't ask him to fix your printer."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 33


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON
