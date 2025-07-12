extends EffectCardType


func get_id() -> int:
    return 192


func get_title() -> String:
    return "Rule of Strength"


func get_text() -> String:
    return "If you control Rule 22, destroy your opponent's most powerful Minion."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 206


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not CardEffects.has_rule_22(playing_field, owner):
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    # Destroy enemy's most powerful Minion
    var target_minion = _find_target(playing_field, CardPlayer.other(owner))
    if target_minion == null:
        # No minions in play
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    var can_influence = target_minion.card_type.do_influence_check(playing_field, target_minion, card, false)
    if not can_influence:
        # Effect was blocked
        return

    await CardGameApi.destroy_card(playing_field, target_minion)


func _find_target(playing_field, opponent: StringName):
    return CardEffects.most_powerful_minion(playing_field, opponent)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    if not CardEffects.has_rule_22(playing_field, player):
        return score

    var target = _find_target(playing_field, CardPlayer.other(player))
    if target == null:
        return score

    var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, target, self, player)
    if not can_influence:
        return score

    var value_of_target = target.card_type.ai_get_expected_remaining_score(playing_field, target)
    score += value_of_target * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
