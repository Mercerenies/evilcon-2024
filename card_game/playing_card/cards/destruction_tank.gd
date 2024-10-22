extends MinionCardType


func get_id() -> int:
    return 159


func get_title() -> String:
    return "Destruction Tank"


func get_text() -> String:
    return "[i]The ultimate in destructive capabilities. An invincible tank that can trample any target, and then blow it up anyway for good measure.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 180


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
