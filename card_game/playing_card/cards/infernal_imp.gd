extends MinionCardType


func get_id() -> int:
    return 131


func get_title() -> String:
    return "Infernal Imp"


func get_text() -> String:
    return "[i]He's constantly causing just enough trouble to get noticed by his dark master.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 122


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.DEMON]


func get_rarity() -> int:
    return Rarity.COMMON
