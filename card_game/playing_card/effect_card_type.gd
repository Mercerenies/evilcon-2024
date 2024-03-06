class_name EffectCardType
extends CardType


func is_ongoing() -> bool:
    return false


func is_hero() -> bool:
    return false


func get_archetypes_row_text() -> String:
    if is_hero():
        return "(Effect / Hero)"
    elif is_ongoing():
        return "(Effect / Ongoing)"
    else:
        return "(Effect)"
