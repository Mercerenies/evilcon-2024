extends TimedCardType


func get_id() -> int:
    return 58


func get_title() -> String:
    return "Cover of Moonlight"


func get_text() -> String:
    return "Your Minions are immune to enemy card effects. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 16


func get_rarity() -> int:
    return Rarity.RARE


func do_broadcasted_influence_check(playing_field, card, target_card, source_card, silently: bool) -> bool:
    if card.owner == target_card.owner and card.owner != source_card.owner:
        if not silently:
            Stats.show_text(playing_field, target_card, PopupText.BLOCKED)
        return false
    return super.do_broadcasted_influence_check(playing_field, card, target_card, source_card, silently)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # See how many cards are in play and NOT protected by Ninja
    # immunity.
    var hypothetical_attacker = PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN)
    var unprotected_minions = (
        Query.on(playing_field).minions(player)
        .filter(Query.influenced_by(hypothetical_attacker, CardPlayer.other(player)))
        .map_sum(Query.remaining_ai_value().value())
    )
    score += unprotected_minions * priorities.of(LookaheadPriorities.IMMUNITY)

    return score


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    # Any unprotected Minions get an extra turn of immunity. This
    # slightly overcounts, if the Minion in question expires, but we
    # don't know exactly how many extra turns we're considering
    # gaining.
    var hypothetical_attacker = PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN)
    var unprotected_minions = (
        Query.on(playing_field).minions(player)
        .filter(Query.influenced_by(hypothetical_attacker, CardPlayer.other(player)))
        .map_sum(Query.remaining_ai_value().value())
    )
    score += unprotected_minions * priorities.of(LookaheadPriorities.IMMUNITY)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # Newly-played Minions are immune, so increase the score unless
    # that Minion already had immunity from another source.
    if target_card_type is MinionCardType:
        var hypothetical_attacker = PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN)
        var hypothetical_defender = Card.new(target_card_type, player)
        if CardEffects.do_hypothetical_influence_check(playing_field, hypothetical_defender, hypothetical_attacker, CardPlayer.other(player)):
            score += priorities.of(LookaheadPriorities.IMMUNITY) * target_card_type.ai_get_expected_remaining_score(playing_field, null)
    return score
