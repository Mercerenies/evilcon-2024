extends MinionCardType


func get_id() -> int:
    return 9


func get_title() -> String:
    return "Pentagon Protector"


func get_text() -> String:
    return "[i]The Pentagon Protectors are a renowned league of sentries, respected by the top officials of the Icosaking's army.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 7


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.SHAPE]


func get_rarity() -> int:
    return Rarity.UNCOMMON
