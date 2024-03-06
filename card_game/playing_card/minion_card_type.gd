class_name MinionCardType
extends CardType


func get_archetypes() -> Array:
    push_warning("Forgot to override get_archetypes!")
    return []


func get_icon_row() -> Array:
    return super.get_icon_row() + get_archetypes().map(Archetype.to_icon_index)
