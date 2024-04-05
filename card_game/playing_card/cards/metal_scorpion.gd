extends MinionCardType


func get_id() -> int:
    return 75


func get_title() -> String:
    return "Metal Scorpion"


func get_text() -> String:
    return "[i]Billions of military research dollars went into making a more potent poison to power this scorpion's vicious stinger attack.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 104


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.COMMON
