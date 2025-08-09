class_name EffectCardType
extends CardType


func is_ongoing() -> bool:
    return false


func is_hero() -> bool:
    return false


func is_dice() -> bool:
    return false


func get_archetypes_row_text() -> String:
    if is_hero():
        return "(Effect / Hero)"
    elif is_dice():
        return "(Effect / Dice)"
    elif is_ongoing():
        return "(Effect / Ongoing)"
    else:
        return "(Effect)"


func get_stats_text() -> String:
    return ""


func get_destination_strip(playing_field, owner: StringName):
    return playing_field.get_effect_strip(owner)
