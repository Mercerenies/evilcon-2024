extends EffectCardType


func get_id() -> int:
    return 179


func get_title() -> String:
    return "Deal with the Devil"


func get_text() -> String:
    return "Gain 4 EP immediately when you play this card. During your End Phase, if you control more than one Minion, destroy this card and all Minions you control."


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 175


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, this_card) -> void:
    await super.on_play(playing_field, this_card)
    await CardGameApi.highlight_card(playing_field, this_card)
    await Stats.add_evil_points(playing_field, this_card.owner, 4)


func on_end_phase(playing_field, this_card) -> void:
    await super.on_end_phase(playing_field, this_card)
    if this_card.owner == playing_field.turn_player:
        await _do_minion_check(playing_field, this_card)


func _do_minion_check(playing_field, this_card) -> void:
    var minions = playing_field.get_minion_strip(this_card.owner).cards()
    if minions.card_count() > 1:
        await CardGameApi.highlight_card(playing_field, this_card)
        for minion in minions.card_array():
            var can_influence = minion.card_type.do_influence_check(playing_field, minion, this_card, false)
            if can_influence:
                await CardGameApi.destroy_card(playing_field, minion)
        await CardGameApi.destroy_card(playing_field, this_card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Immediate effect
    score += 4.0 * priorities.of(LookaheadPriorities.EVIL_POINT)

    # If we have too many Minions, then assume they'll all die.
    var all_minions = Query.on(playing_field).minions(player).array()
    if len(all_minions) > 1:
        for minion in all_minions:
            score -= minion.card_type.ai_get_value_of_destroying(playing_field, minion, priorities)

    # Opportunity cost from the Minions we likely won't play.
    score -= priorities.of(LookaheadPriorities.DEVIL_OPPORTUNITY)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType):
        return score

    var all_minions = Query.on(playing_field).minions(player).array()
    if len(all_minions) == 1:
        # Playing this Minion *will* trigger Deal with the Devil. All
        # Minions will be destroyed.
        for minion in all_minions:
            score -= minion.card_type.ai_get_value_of_destroying(playing_field, minion, priorities)
    if len(all_minions) >= 1:
        score -= target_card_type.ai_get_value_of_destroying(playing_field, null, priorities)

    return score
