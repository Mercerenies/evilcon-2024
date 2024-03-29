extends MinionCardType


func get_id() -> int:
    return 46


func get_title() -> String:
    return "Worker Bee"


func get_text() -> String:
    return "[i]Diligently delving its daily duties, darting from daisy to daisy for delectable drops.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 96


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.BEE]


func get_rarity() -> int:
    return Rarity.COMMON
