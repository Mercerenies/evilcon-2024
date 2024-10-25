extends EffectCardType


func get_id() -> int:
    return 117


func get_title() -> String:
    return "Needle Strike"


func get_text() -> String:
    return "Deal 1 damage to your opponent's fortress for each \"Spiky\" Minion you control."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 141


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    await CardGameApi.highlight_card(playing_field, card)
    var opponent = CardPlayer.other(card.owner)
    var own_minions = playing_field.get_minion_strip(card.owner).cards().card_array()
    if not own_minions.any(func (m): return m.card_type.is_spiky(playing_field, m)):
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    for minion_card in own_minions:
        if minion_card.card_type.is_spiky(playing_field, minion_card):
            await CardGameApi.highlight_card(playing_field, minion_card)
            await Stats.add_fort_defense(playing_field, opponent, -1)
