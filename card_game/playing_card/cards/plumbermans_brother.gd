extends EffectCardType


func get_id() -> int:
    return 70


func get_title() -> String:
    return "Plumberman's Brother"


func get_text() -> String:
    return "Destroy your opponent's second most powerful Minion."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 72


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return

    # Destroy enemy's second most powerful Minion
    var target_minion = _get_second_most_powerful_minion(playing_field, CardPlayer.other(owner))
    if target_minion == null:
        # Zero or one minions in play
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    var can_influence = target_minion.card_type.do_influence_check(playing_field, target_minion, card, false)
    if not can_influence:
        # Effect was blocked
        return

    await CardGameApi.destroy_card(playing_field, target_minion)


func _get_second_most_powerful_minion(playing_field, owner):
    var minions = CardGameApi.get_minions_in_play(playing_field)
    minions = minions.filter(func (minion): return minion.owner == owner)
    if len(minions) <= 1:
        return null
    minions.sort_custom(CardEffects.card_power_less_than(playing_field))
    return minions[-2]


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.PASSIVE_FAIL:
        return score
    elif hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
        return score

    var target = _get_second_most_powerful_minion(playing_field, CardPlayer.other(player))
    if target == null:
        return score

    var value_of_target = target.card_type.get_level(playing_field, target) * target.card_type.get_morale(playing_field, target)
    score += value_of_target * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
