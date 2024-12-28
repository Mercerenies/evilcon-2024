extends EffectCardType


func get_id() -> int:
    return 171


func get_title() -> String:
    return "Poison Cloud"


func get_text() -> String:
    return "[font_size=12]Minions played by your opponent are at -1 Level. During your Standby Phase, destroy this card if you have no [icon]NATURE[/icon] NATURE Minions.[/font_size]"


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 166


func get_rarity() -> int:
    return Rarity.RARE


func on_standby_phase(playing_field, this_card) -> void:
    if this_card.owner == playing_field.turn_player and not _has_any_nature_minions(playing_field, this_card.owner):
        await CardGameApi.highlight_card(playing_field, this_card)
        await CardGameApi.destroy_card(playing_field, this_card)


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if this_card.owner == played_card.owner:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        await Stats.add_level(playing_field, played_card, -1)


func _has_any_nature_minions(playing_field, owner) -> bool:
    var all_minions = playing_field.get_minion_strip(owner).cards().card_array()
    return all_minions.any(func(c): return c.has_archetype(playing_field, Archetype.NATURE))


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var odds_of_drawing_successfully = _ai_probability_of_drawing_nature_card(playing_field, player)
    if odds_of_drawing_successfully == 1.0:
        # This card will survive indefinitely, until the opponent does
        # something about it. This will only really happen if this
        # character's deck has been thinned to a ridiculously low
        # number of cards, all of them NATURE cards. To avoid dividing
        # by zero, arbitrarily lower the probability to 99%.
        odds_of_drawing_successfully = 0.99

    var expected_turns_to_live = 1.0 / (1.0 - odds_of_drawing_successfully)
    # The opponent gets 8 EP per turn (by default). As of Dec 28,
    # 2024, the average EP cost of a playing card is 3.2. So assume
    # that the opponent is playing 2 or 3 cards per turn. Here, we
    # assume the opponent is playing 2 Minion cards per turn. The
    # average Morale of a Minion is 1.7, so if we decrease the Level
    # of that Minion, it's worth 1.7 less. Thus, every turn this card
    # survives is worth 1.7 * 2 = 3.4 to the owner, on average.
    var expected_value_per_turn = 3.4

    if not _ai_is_poison_cloud_satisfied_next_turn(playing_field, player):
        # We will expire on Turn 2.
        expected_turns_to_live = 1.0

    score += expected_value_per_turn * expected_turns_to_live

    return score


func _ai_count_total_nature_minions_owned(playing_field, player: StringName) -> int:
    return Query.on(playing_field).full_deck(player).count(Query.by_archetype(Archetype.NATURE))


func _ai_count_parasites_in_play(playing_field, player: StringName) -> int:
    var this_id = get_id()
    return (
        Query.on(playing_field).effects(player)
        .count(Query.by_id(this_id))
    )


func _ai_probability_of_drawing_nature_card(playing_field, player: StringName) -> float:
    var total_card_count = Query.on(playing_field).full_deck(player).count()
    var nature_card_count = _ai_count_total_nature_minions_owned(playing_field, player)
    var cards_per_turn = StatsCalculator.get_cards_per_turn(playing_field, player)
    var cards_needed_per_turn = 1 + _ai_count_parasites_in_play(playing_field, player)

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


func _ai_is_poison_cloud_satisfied_next_turn(playing_field, player: StringName) -> bool:
    # We need to play out what will happen over the next turn.
    var nature_minions_by_value = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.NATURE))
        .sorted().array()
    )

    # First, any Invasive Parasites get to sacrifice a Minion.
    var parasites_in_play = _ai_count_parasites_in_play(playing_field, player)
    nature_minions_by_value = nature_minions_by_value.slice(parasites_in_play)

    # Next, any Minion with one Morale expires.
    nature_minions_by_value = nature_minions_by_value.filter(func(m):
        return m.card_type.get_morale(playing_field, m) > 1)

    # If there are any Minions left, we are satisfied.
    return len(nature_minions_by_value) > 0


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # If we control Poison Cloud and do not have enough Minions to
    # sustain it, prioritize NATURE cards with minimum Morale 2.
    if target_card_type is MinionCardType and Archetype.NATURE in target_card_type.get_base_archetypes():
        if target_card_type.get_base_morale() > 1 and not _ai_is_poison_cloud_satisfied_next_turn(playing_field, player):
            # Poison Cloud will expire. NOT playing this now would
            # suffer a wrong-order combo penalty.
            score += priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score


func ai_get_score_broadcasted_in_hand(playing_field, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted_in_hand(playing_field, player, priorities, target_card_type)

    # If there's a Poison Cloud in our hand and we can play a NATURE Minion
    # of Morale at least 2 *and* Poison Cloud, then play the Minion.
    if target_card_type is MinionCardType and Archetype.NATURE in target_card_type.get_base_archetypes():
        if target_card_type.get_base_morale() > 1 and not _ai_is_poison_cloud_satisfied_next_turn(playing_field, player):
            var evil_points = playing_field.get_stats(player).evil_points
            if evil_points > get_star_cost() + target_card_type.get_star_cost():
                # Playing this right now is a right-order combo.
                score += priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score
