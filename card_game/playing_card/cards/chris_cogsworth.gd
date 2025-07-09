extends MinionCardType


func get_id() -> int:
    return 151


func get_title() -> String:
    return "Chris Cogsworth"


func get_text() -> String:
    return "When Chris Cogsworth expires, all of your effects which \"last X turns\" last an extra turn."


func get_picture_index() -> int:
    return 155


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    await CardGameApi.highlight_card(playing_field, this_card)

    var succeeded = false
    for card in playing_field.get_effect_strip(this_card.owner).cards().card_array():
        if await _try_to_apply(playing_field, this_card, card):
            succeeded = true
    if not succeeded:
        # There were no valid targets, so show appropriate UI.
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)


# Returns true if the target was valid (even if the influence check
# failed)
func _try_to_apply(playing_field, this_card, target_card) -> bool:
    if this_card.owner != target_card.owner:
        return false
    if not (CardMeta.TURN_COUNTER in target_card.metadata):
        return false

    var can_influence = target_card.card_type.do_influence_check(playing_field, target_card, this_card, false)
    if can_influence:
        target_card.metadata[CardMeta.TURN_COUNTER] -= 1
    playing_field.emit_cards_moved()
    return true


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Count all of the TimedCardTypes that will outlive Chris.
    var chris_morale = get_base_morale()
    score += (
        Query.on(playing_field).effects(player)
        .filter([Query.is_timed_effect, Query.turn_count().at_least(chris_morale)])
        .map_sum(func (playing_field, card):
            return card.card_type.ai_get_score_per_turn(playing_field, player, priorities))
    )

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)

    if this_card.owner != player:
        return score

    # If we control Chris, then TimedCardTypes that will outlive him
    # get one extra turn.
    var chris_morale = get_morale(playing_field, this_card)
    if target_card_type is TimedCardType and target_card_type.get_total_turn_count() >= chris_morale:
        score += target_card_type.ai_get_score_per_turn(playing_field, player, priorities)

    return score
