extends EffectCardType


func get_id() -> int:
    return 154


func get_title() -> String:
    return "Extended Warranty"


func get_text() -> String:
    return "All of your effects which \"last X turns\" last an extra turn."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 160


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var succeeded = false
    for card in playing_field.get_effect_strip(this_card.owner).cards().card_array():
        if await _try_to_apply(playing_field, this_card, card):
            succeeded = true
    if not succeeded:
        # There were no valid targets, so show appropriate UI.
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)


# Returns true if the target was valid (even if the influence check
# failed)
func _try_to_apply(playing_field, this_card, target_card) -> bool:
    if this_card.owner != target_card.owner:
        return false
    if not (CardMeta.TURN_COUNTER in target_card.metadata):
        return false

    var can_influence = await target_card.card_type.do_influence_check(playing_field, target_card, this_card, false)
    if can_influence:
        target_card.metadata[CardMeta.TURN_COUNTER] -= 1
    playing_field.emit_cards_moved()
    return true
