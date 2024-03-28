extends MinionCardType


func get_id() -> int:
    return 27


func get_title() -> String:
    return "Robot Assistant"


func get_text() -> String:
    return "[i]He can tell you the weather, make jokes, play your favorite playlists, and slaughter your enemies.[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 59


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.UNCOMMON
