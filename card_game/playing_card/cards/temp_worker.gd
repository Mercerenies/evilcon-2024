extends MinionCardType


func get_id() -> int:
    return 22


func get_title() -> String:
    return "Temp Worker"


func get_text() -> String:
    return "[i]His spreadsheet powers are unmatched... for the next six to eight weeks anyway.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 32


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON
