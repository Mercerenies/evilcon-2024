extends EffectCardType


func get_id() -> int:
    return 88


func get_title() -> String:
    return "Ravenboy"


func get_text() -> String:
    return "Exile the top card of your opponent's deck; then exile Ravenboy. Limit 1 per deck."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 76


func is_hero() -> bool:
    return true


func is_limited() -> bool:
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

    var enemy_deck = playing_field.get_deck(CardPlayer.other(owner))
    if enemy_deck.cards().card_count() == 0:
        # No cards in opponent's deck
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return false

    await CardEffects.exile_top_of_deck(playing_field, CardPlayer.other(owner))
    return false


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.PASSIVE_FAIL:
        return score
    elif hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
        return score

    # If we get to this point, then activation of Ravenboy would exile
    # him, so we factor that into the cost.
    score -= priorities.of(LookaheadPriorities.SINGLE_USE_EXILE)
    # We will exile a card at random.
    if Query.on(playing_field).deck(CardPlayer.other(player)).any():
        score += priorities.of(LookaheadPriorities.BLIND_EXILE)

    return score
