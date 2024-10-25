extends EffectCardType


func get_id() -> int:
    return 155


func get_title() -> String:
    return "Ninja Mask"


func get_text() -> String:
    return "Your most powerful Minion is now immune to enemy card effects."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 157


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner

    var most_powerful_minion = CardEffects.most_powerful_minion(playing_field, owner)
    if most_powerful_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return
    most_powerful_minion.metadata[CardMeta.HAS_SPECIAL_IMMUNITY] = true
    playing_field.emit_cards_moved()
