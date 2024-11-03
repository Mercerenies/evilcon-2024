extends MinionCardType


func get_id() -> int:
    return 144


func get_title() -> String:
    return "Foreman"


func get_text() -> String:
    return "Cards you play which \"last X turns\" last an extra turn."


func get_picture_index() -> int:
    return 144


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if this_card.owner != played_card.owner:
        return
    if not (CardMeta.TURN_COUNTER in played_card.metadata):
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        played_card.metadata[CardMeta.TURN_COUNTER] -= 1
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # If we are holding any TimedCardTypes in hand that we can ALSO
    # play this turn, then Foreman is an even better move.
    var evil_points = playing_field.get_stats(player).evil_points
    for card_in_hand in playing_field.get_hand(player).cards().card_array():
        if not (card_in_hand is TimedCardType):
            continue
        if evil_points >= get_star_cost() + card_in_hand.get_star_cost():
            score += card_in_hand.ai_get_score_per_turn(playing_field, player, priorities)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)

    # If we control Foreman, add one turn to TimedCardTypes we play.
    if target_card_type is TimedCardType:
        score += target_card_type.ai_get_score_per_turn(playing_field, player, priorities)

    return score


func ai_get_score_broadcasted_in_hand(playing_field, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted_in_hand(playing_field, player, priorities, target_card_type)

    # If Foreman is in the hand and we can afford to play both, then
    # we should play him BEFORE TimedCardTypes.
    var evil_points = playing_field.get_stats(player).evil_points
    if target_card_type is TimedCardType and evil_points >= get_star_cost() + target_card_type.get_star_cost():
        score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score
