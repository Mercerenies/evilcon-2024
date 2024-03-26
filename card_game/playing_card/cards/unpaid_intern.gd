extends MinionCardType


func get_id() -> int:
    return 17


func get_title() -> String:
    return "Unpaid Intern"


func get_text() -> String:
    return "Just three more years of experience and he'll be promoted to an unpaid temp worker."


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 31


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON
