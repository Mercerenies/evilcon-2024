extends EffectCardType


func get_id() -> int:
    return 206


func get_title() -> String:
    return "Little Diceman"


func get_text() -> String:
    return "Discard all Dice cards from your hand. For each card discarded, a random enemy Minion loses 1 Morale."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 214


func get_rarity() -> int:
    return Rarity.RARE


func is_hero() -> bool:
    return true


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)

    if not await CardEffects.do_hero_check(playing_field, this_card):
        # Effect was blocked
        return

    var owner = this_card.owner
    var opponent = CardPlayer.other(owner)
    var cards_to_discard = (
        playing_field.get_hand(owner).cards().card_array()
        .filter(func(c): return c is EffectCardType and c.is_dice())
    )
    for card in cards_to_discard:
        await CardGameApi.discard_card(playing_field, owner, card)
        var enemy_minions = playing_field.get_minion_strip(opponent).cards().card_array()
        if len(enemy_minions) == 0:
            continue
        var chosen_minion = playing_field.randomness.choose(enemy_minions)
        var can_influence = chosen_minion.card_type.do_influence_check(playing_field, chosen_minion, this_card, false)
        if can_influence:
            await Stats.add_morale(playing_field, chosen_minion, -1)
    await CardEffects.broadcast_discards(playing_field, owner, cards_to_discard)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.PASSIVE_FAIL:
        return score
    elif hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
        return score

    var cards_to_discard = len(
        playing_field.get_hand(player).cards().card_array()
        .filter(func(c): return c is EffectCardType and c.is_dice())
    )

    # In principle, we should pay CARD_IN_HAND for each card
    # discarded. But we don't because "being discarded for Little
    # Diceman" is literally the only point of Dice cards.

    #score -= cards_to_discard * priorities.of(LookaheadPriorities.CARD_IN_HAND)

    var enemy_minions = playing_field.get_minion_strip(CardPlayer.other(player)).cards().card_array()
    var average_enemy_level = 0.0
    if len(enemy_minions) > 0:
        average_enemy_level = Util.sum(enemy_minions.map(func (m): return m.card_type.get_level(playing_field, m))) / float(len(enemy_minions))
    score += cards_to_discard * average_enemy_level * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
