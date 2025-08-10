extends EffectCardType


func get_id() -> int:
    return 184


func get_title() -> String:
    return "Poultry Farm"


func get_text() -> String:
    return "During your Standby Phase, summon a Chicken from your deck to the field. If you have no such cards in your deck, destroy this card."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 184


func get_rarity() -> int:
    return Rarity.UNCOMMON


func is_ongoing() -> bool:
    return true


func on_standby_phase(playing_field, this_card) -> void:
    await super.on_standby_phase(playing_field, this_card)
    if this_card.owner == playing_field.turn_player:
        await _evaluate_effect(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_chicken_card_type)
    if len(valid_target_minions) == 0:
        await CardGameApi.destroy_card(playing_field, this_card)
    else:
        # Choose a target minion and play
        var target_minion = valid_target_minions[-1]
        await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    var total_chickens = (
        Query.on(playing_field)
        .deck(player)
        .count(Query.by_id(PlayingCardCodex.ID.CHICKEN))
    )
    var value_of_chicken = 1.0
    score += total_chickens * value_of_chicken

    # If we're about to reshuffle, then also consider chickens in the
    # discard pile.
    if _ai_will_reshuffle_next_turn(playing_field, player):
        var chickens_in_discard = (
            Query.on(playing_field)
            .discard_pile(player)
            .count(Query.by_id(PlayingCardCodex.ID.CHICKEN))
        )
        score += chickens_in_discard * value_of_chicken

    return score


func _ai_will_reshuffle_next_turn(playing_field, player: StringName) -> bool:
    var cards_in_deck = playing_field.get_deck(player).cards().card_count()

    var cards_in_hand = playing_field.get_hand(player).cards().card_count()
    var cards_per_turn = StatsCalculator.get_cards_per_turn(playing_field, player)
    var max_hand_size = StatsCalculator.get_hand_limit(playing_field, player)
    var cards_to_draw = mini(cards_per_turn, max_hand_size - cards_in_hand)
    return cards_in_deck < cards_to_draw


func _is_chicken_card_type(card_type) -> bool:
    return card_type.get_id() == PlayingCardCodex.ID.CHICKEN
