extends EffectCardType


func get_id() -> int:
    return 83


func get_title() -> String:
    return "Rhombicuboctahedron"


func get_text() -> String:
    return "Destroy all opponent Minions with 1 Morale."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 114


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _do_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _do_effect(playing_field, card) -> void:
    var owner = card.owner

    var opponent_minions_to_destroy = (
        playing_field.get_minion_strip(CardPlayer.other(owner))
        .cards().card_array()
        .filter(func(target_card): return target_card.card_type.get_morale(playing_field, target_card) <= 1)
    )
    if len(opponent_minions_to_destroy) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        for minion in opponent_minions_to_destroy:
            var can_influence = minion.card_type.do_influence_check(playing_field, minion, card, false)
            if can_influence:
                await CardGameApi.destroy_card(playing_field, minion)
