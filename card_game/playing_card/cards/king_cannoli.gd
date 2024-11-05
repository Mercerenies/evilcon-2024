extends EffectCardType


func get_id() -> int:
    return 86


func get_title() -> String:
    return "King Cannoli"


func get_text() -> String:
    return "Discard your entire hand; your most powerful Minion gains Morale equal to the number of cards discarded; then exile King Cannoli."


func get_star_cost() -> int:
    return 8


func get_picture_index() -> int:
    return 90


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

    # Discard all cards from hand
    var hand_cards = playing_field.get_hand(owner).cards().card_array()
    for card_type in hand_cards:
        await CardGameApi.discard_card(playing_field, owner, card_type)

    # Find most powerful Minion
    var most_powerful_minion = CardEffects.most_powerful_minion(playing_field, owner)
    if most_powerful_minion == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        var can_influence = most_powerful_minion.card_type.do_influence_check(playing_field, most_powerful_minion, card, false)
        if can_influence:
            await Stats.add_morale(playing_field, most_powerful_minion, len(hand_cards))

    return false


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.PASSIVE_FAIL:
        return score
    elif hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
        return score

    # If we get to this point, then activation of King Cannoli
    # would exile him, so we factor that into the cost.
    score -= priorities.of(LookaheadPriorities.SINGLE_USE_EXILE)

    var cards_in_hand = Query.on(playing_field).hand(player).count() - 1
    score -= cards_in_hand * priorities.of(LookaheadPriorities.CARD_IN_HAND)

    var most_powerful_minion = CardEffects.most_powerful_minion(playing_field, player)
    if most_powerful_minion != null:
        var level = most_powerful_minion.card_type.get_level(playing_field, most_powerful_minion)
        score += level * cards_in_hand * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
