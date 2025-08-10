extends TimedCardType


func get_id() -> int:
    return 208


func get_title() -> String:
    return "The Inquisitor"


func get_text() -> String:
    return "Players lose 1 Evil Point whenever they play a Minion. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 223


func get_rarity() -> int:
    return Rarity.RARE


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    if not (played_card.card_type is MinionCardType):
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    await Stats.add_evil_points(playing_field, played_card.owner, -1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Both players will suffer roughly equally on most turns, but The
    # Inquisitor costs the opponent one extra turn. Assume the
    # opponent plays 2 or 3 Minions per turn. That's 2 or 3 extra EP
    # they lose on that "extra" turn.
    score += 2.5 * priorities.of(LookaheadPriorities.EVIL_POINT)

    # If we have any other Minions we can play first, we should do
    # that before playing The Inquisitor.
    var has_other_minions = false
    var evil_points_left = playing_field.get_stats(player).evil_points - self.get_star_cost()
    for card_in_hand in Query.on(playing_field).hand(player).array():
        if card_in_hand is MinionCardType and card_in_hand.get_star_cost() <= evil_points_left:
            has_other_minions = true
            break
    if has_other_minions:
        score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score


func ai_get_score_per_turn(_playing_field, _player: StringName, _priorities) -> float:
    # So the main benefit of The Inquisitor comes from the fact that
    # the player who plays it suffers from it for one fewer turn.
    # Adding one turn to the counter causes both players to suffer, in
    # principle, equally. So this is a wash.
    return 0.0


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)

    # If anyone controls The Inquisitor, Minions effectively cost 1 extra.
    if target_card_type is MinionCardType:
        score -= priorities.of(LookaheadPriorities.EVIL_POINT)

    return score
