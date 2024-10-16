extends MinionCardType


func get_id() -> int:
    return 132


func get_title() -> String:
    return "Greedy Goblin"


func get_text() -> String:
    return "[i]A goblin would sell his own grandmother for a pretty penny. And then he'd sell the penny too, if it fetched him something shinier.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 123


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON]


func get_rarity() -> int:
    return Rarity.UNCOMMON
