extends EffectCardType


func get_id() -> int:
    return 157


func get_title() -> String:
    return "Invasive Parasites"


func get_text() -> String:
    return "[font_size=12]During your End Phase, destroy your weakest [icon]NATURE[/icon] NATURE Minion, then destroy a random enemy Minion. If you have no such Minions, destroy this card.[/font_size]"


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 164


func get_rarity() -> int:
    return Rarity.RARE


func on_end_phase(playing_field, this_card) -> void:
    if this_card.owner == playing_field.turn_player:
        await _try_to_perform_effect(playing_field, this_card)
    await super.on_end_phase(playing_field, this_card)


func _try_to_perform_effect(playing_field, this_card) -> void:
    var owner = this_card.owner

    await CardGameApi.highlight_card(playing_field, this_card)

    var friendly_nature_minions = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func(c): return c.has_archetype(playing_field, Archetype.NATURE))
    )
    if len(friendly_nature_minions) == 0:
        await CardGameApi.destroy_card(playing_field, this_card)
        return

    friendly_nature_minions.sort_custom(CardEffects.card_power_less_than(playing_field))
    var minion_to_destroy = friendly_nature_minions[0]
    var can_tribute = minion_to_destroy.card_type.do_influence_check(playing_field, minion_to_destroy, this_card, false)
    if not can_tribute:
        return

    await CardGameApi.destroy_card(playing_field, minion_to_destroy)
    var enemy_minions = (
        playing_field.get_minion_strip(CardPlayer.other(owner))
        .cards().card_array()
    )
    if len(enemy_minions) == 0:
        # No minions in play
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var target_enemy_minion = playing_field.randomness.choose(enemy_minions)
    var can_destroy = target_enemy_minion.card_type.do_influence_check(playing_field, target_enemy_minion, this_card, false)
    if can_destroy:
        await CardGameApi.destroy_card(playing_field, target_enemy_minion)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    # This is a complicated one. We start by calculating the (known)
    # value of the first turn of Invasive Parasites, assuming we end
    # our turn right after playing it. Technically we *could* play a
    # NATURE Minion after playing this, but we could also do it in the
    # opposite order, so supporting one order and not the other is
    # fine.
    var score = super.ai_get_score(playing_field, player, priorities)

    var first_turn_value = _ai_get_expected_score_first_turn(playing_field, player, priorities)
    if first_turn_value == null:
        # This card will die on Turn 1 and do nothing of value.
        return score
    score += first_turn_value

    var odds_of_drawing_successfully = _ai_probability_of_drawing_nature_card(playing_field, player)
    if odds_of_drawing_successfully == 0.0:
        # This card will die on Turn 2.
        return score
    elif odds_of_drawing_successfully == 1.0:
        # This card will survive indefinitely, until the opponent does
        # something about it. This will only really happen if this
        # character's deck has been thinned to a ridiculously low
        # number of cards, all of them NATURE cards. To avoid dividing
        # by zero, arbitrarily lower the probability to 99%.
        odds_of_drawing_successfully = 0.99

    var expected_turns_to_live = 1.0 / (1.0 - odds_of_drawing_successfully)
    # As of Dec 9, 2024, the average EP cost of a playing card is 3.2.
    # Assume opponent is playing Minions at curve, so we can knock out
    # a 3.2-value Minion every turn.
    var expected_value_per_turn = 3.2
    score += expected_turns_to_live * expected_value_per_turn

    return score


func _ai_get_expected_score_first_turn(playing_field, player: StringName, priorities):
    var nature_minions_by_value = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.NATURE))
        .sorted().array()
    )
    var parasites_in_play = _ai_count_parasites_in_play(playing_field, player)
    if len(nature_minions_by_value) < parasites_in_play + 1:
        # In this case, we've wasted this card. It does nothing, and
        # we spent 4 EP for no reason.
        return null
    var weakest_nature_minion = nature_minions_by_value[parasites_in_play]

    var possible_target_values = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .map(func (playing_field, card):
                 if not CardEffects.do_hypothetical_influence_check(playing_field, card, self, player):
                     return 0.0  # Cannot influence
                 else:
                     return card.card_type.ai_get_expected_remaining_score(playing_field, card))
    )

    var score = 0.0
    score -= weakest_nature_minion.card_type.ai_get_value_of_destroying(playing_field, weakest_nature_minion, priorities)
    if len(possible_target_values) != 0:
        score += Util.sum(possible_target_values) / len(possible_target_values)

    if _ai_controls_poison_cloud(playing_field, player) and len(nature_minions_by_value) == parasites_in_play + 1:
        # If we control a Poison Cloud and have *exactly* enough
        # Minions to keep these Invasive Parasites in play, then we'll
        # lose the Poison Cloud. In that case, playing this card
        # before playing the extra NATURE Minion triggers a wrong
        # order combo penalty.
        score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score


func _ai_count_total_nature_minions_owned(playing_field, player: StringName) -> int:
    return Query.on(playing_field).full_deck(player).count(Query.by_archetype(Archetype.NATURE))


func _ai_probability_of_drawing_nature_card(playing_field, player: StringName) -> float:
    var total_card_count = Query.on(playing_field).full_deck(player).count()
    var nature_card_count = _ai_count_total_nature_minions_owned(playing_field, player)
    var cards_per_turn = StatsCalculator.get_cards_per_turn(playing_field, player)
    var cards_needed_per_turn = 1 + _ai_count_parasites_in_play(playing_field, player)

    if _ai_controls_poison_cloud(playing_field, player):
        # Technically, Poison Clouds don't sacrifice their Minions, so
        # we can "reuse" the same Minion for a couple of turns. But on
        # average, we'll need to draw an extra Minion to replace the
        # expiring Poison Cloud Minion. So just pretend it's an extra
        # Invasive Parasites for now.
        cards_needed_per_turn += 1

    if cards_per_turn < cards_needed_per_turn:
        # We aren't drawing enough cards to sustain this, so the
        # probability of succeeding is zero.
        return 0.0

    if nature_card_count < cards_needed_per_turn:
        # There aren't enough NATURE cards in our deck to sustain
        # this. Probability of success is zero.
        return 0.0

    if total_card_count <= cards_per_turn:
        # Weird corner case: Our deck is thinned to the point where we
        # draw every card we own on every turn. The AI NEVER goes for
        # deck-thinning strategies, so it would be extremely weird to
        # end up in this case. In this case, if we have enough Nature
        # cards, we're going to draw them every turn.
        return 1.0 if nature_card_count >= cards_needed_per_turn else 0.0

    var ways_of_failing_draw = 0.0
    for j in range(cards_needed_per_turn):
        ways_of_failing_draw += Util.ncr(nature_card_count, j) * Util.ncr(total_card_count - nature_card_count, cards_per_turn - j)

    var odds_of_failing_draw = ways_of_failing_draw / float(Util.ncr(total_card_count, cards_per_turn))
    return 1.0 - odds_of_failing_draw


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # If we control Invasive Parasite and not enough NATURE Minions,
    # prioritize NATURE cards.
    var nature_minion_count = (
        Query.on(playing_field).minions(player)
        .count(Query.by_archetype(Archetype.NATURE))
    )

    var parasite_count = _ai_count_parasites_in_play(playing_field, player)
    if _ai_controls_poison_cloud(playing_field, player):
        parasite_count += 1

    if parasite_count > nature_minion_count and target_card_type is MinionCardType and Archetype.NATURE in target_card_type.get_base_archetypes():
        # Invasive Parasites will expire. NOT playing this now would
        # suffer a wrong-order combo penalty.
        score += priorities.of(LookaheadPriorities.RIGHT_ORDER)
    return score


func _ai_count_parasites_in_play(playing_field, player: StringName) -> int:
    var this_id = get_id()
    return (
        Query.on(playing_field).effects(player)
        .count(Query.by_id(this_id))
    )


func _ai_controls_poison_cloud(playing_field, player: StringName) -> bool:
    var poison_cloud_id = PlayingCardCodex.ID.POISON_CLOUD
    return (
        Query.on(playing_field).effects(player)
        .any(Query.by_id(poison_cloud_id))
    )
