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


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var target = CardEffects.most_powerful_minion(playing_field, player)
    if target != null:
        var hypothetical_attacker = PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN)
        var is_unprotected = CardEffects.do_hypothetical_influence_check(playing_field, target, hypothetical_attacker, CardPlayer.other(player))
        if is_unprotected:
            score += priorities.of(LookaheadPriorities.IMMUNITY) * target.card_type.ai_get_expected_remaining_score(playing_field, target)

    return score
