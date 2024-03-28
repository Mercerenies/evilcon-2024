extends MinionCardType


func get_id() -> int:
    return 28


func get_title() -> String:
    return "Death Cyborg"


func get_text() -> String:
    return "[i]After a near-death experience, he was augmented with metal parts. The laser guns were his idea, though.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 60


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.UNCOMMON
