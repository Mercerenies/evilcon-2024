extends EffectCardType


func get_id() -> int:
    return 85


func get_title() -> String:
    return "Flying Brickman"


func get_text() -> String:
    return "Destroy all opponent's Minions; then exile Flying Brickman."


func get_star_cost() -> int:
    return 8


func get_picture_index() -> int:
    return 77


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var was_hero_blocked = await _evaluate_effect(playing_field, card)
    if was_hero_blocked:
        # If this card's effect was fully negated (by a hostage card),
        # do not exile.
        await CardGameApi.destroy_card(playing_field, card)
    else:
        await CardGameApi.exile_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> bool:
    # Returns true if the effect was blocked by a Hero-blocking card.
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return true

    # Destroy all enemy Minions
    var target_minions = playing_field.get_minion_strip(CardPlayer.other(owner)).cards().card_array()
    if len(target_minions) == 0:
        # No minions in play
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return false  # Effect was not blocked, you just played it at a dumb moment.

    for target_minion in target_minions:
        var can_influence = target_minion.card_type.do_influence_check(playing_field, target_minion, card, false)
        if can_influence:
            await CardGameApi.destroy_card(playing_field, target_minion)

    return false


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.PASSIVE_FAIL:
        return score
    elif hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
        return score

    # If we get to this point, then activation of Flying Brickman
    # would exile him, so we factor that into the cost.
    score -= priorities.of(LookaheadPriorities.SINGLE_USE_EXILE)

    var target_values = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter(Query.influenced_by(self, player))
        .map_sum(Query.remaining_ai_value().value())
    )
    score += target_values * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
