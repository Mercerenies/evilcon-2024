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


func get_stats_text() -> String:
    return ""


func get_destination_strip(playing_field, owner: StringName):
    return playing_field.get_effect_strip(owner)


func on_play(playing_field, card) -> void:
    var owner = card.owner
    await playing_field.draw_cards(owner, 2)
    # TODO Highlight this card and discard it
