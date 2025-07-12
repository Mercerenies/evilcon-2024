extends EffectCardType


func get_id() -> int:
    return 194


func get_title() -> String:
    return "Rule of Knowledge"


func get_text() -> String:
    return "If you control Rule 22, your opponent discards three cards at random."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 205


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, this_card) -> void:
    await super.on_play(playing_field, this_card)
    await _evaluate_effect(playing_field, this_card)
    await CardGameApi.destroy_card(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var opponent = CardPlayer.other(owner)
    await CardGameApi.highlight_card(playing_field, this_card)

    if not CardEffects.has_rule_22(playing_field, owner):
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var opponent_hand = (
        Query.on(playing_field).hand(opponent).array()
    )
    opponent_hand.shuffle()

    if len(opponent_hand) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        var cards_to_discard = opponent_hand.slice(0, 3)
        for target in cards_to_discard:
            await CardGameApi.discard_card(playing_field, opponent, target)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    if not CardEffects.has_rule_22(playing_field, player):
        return score

    var enemy_cards_in_hand = Query.on(playing_field).hand(CardPlayer.other(player)).count()
    var cards_to_discard = mini(enemy_cards_in_hand, 3)
    score += cards_to_discard * priorities.of(LookaheadPriorities.CARD_IN_HAND)
    return score
