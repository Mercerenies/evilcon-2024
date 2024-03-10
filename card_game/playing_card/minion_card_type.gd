class_name MinionCardType
extends CardType


func get_archetypes() -> Array:
    push_warning("Forgot to override get_archetypes!")
    return []


func get_icon_row() -> Array:
    return super.get_icon_row() + get_archetypes().map(Archetype.to_icon_index)


func get_base_level() -> int:
    push_warning("Forgot to override get_base_level!")
    return 0


func get_base_morale() -> int:
    push_warning("Forgot to override get_base_morale!")
    return 0


func get_stats_text() -> String:
    return "Lvl %s / %s Mor" % [get_base_level(), get_base_morale()]


func get_destination_strip(playing_field, owner: StringName):
    return playing_field.get_minion_strip(owner)
