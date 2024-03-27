extends MinionCardType


func get_id() -> int:
    return 21


func get_title() -> String:
    return "Penne Sharpshooter"


func get_text() -> String:
    return "[i]A sentient noodle with a keen eye and sharp aim. Nobody expects their pasta to be their assassin.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 37


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_archetypes() -> Array:
    return [Archetype.PASTA]


func get_rarity() -> int:
    return Rarity.UNCOMMON
