extends MinionCardType


func get_id() -> int:
    return 72


func get_title() -> String:
    return "Street Mime"


func get_text() -> String:
    return "[i]A stoic entry-level member to the Order of the Mimes. As he moves up the ranks, he'll be rewarded with a fancy hat.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 110


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN]


func get_rarity() -> int:
    return Rarity.COMMON
