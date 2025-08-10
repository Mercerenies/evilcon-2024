extends EffectCardType


func get_id() -> int:
    return 205


func get_title() -> String:
    return "Elvira - Ruler of Ideology"


func get_text() -> String:
    return "If all of your Minions have a common tribe, they all gain 1 Morale."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 220


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner

    if not Query.on(playing_field).minions(owner).any():
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var result = _do_all_minions_match(playing_field, Query.on(playing_field).minions(owner).array())
    if not result[0]:
        Stats.show_text(playing_field, result[1], PopupText.MISMATCH)
        return
    var minions = Query.on(playing_field).minions(owner).array()
    for minion in minions:
        var can_influence = minion.card_type.do_influence_check(playing_field, minion, this_card, false)
        if can_influence:
            await Stats.add_morale(playing_field, minion, 1)


# Returns two elements. If all minions match, returns `[true, null]`.
# If not, returns `[false, c]` where `c` is the first minion that
# caused a mismatch.
func _do_all_minions_match(playing_field, minions: Array):
    if len(minions) <= 1:
        return [true, null]  # Short circuit in the easy case

    # Insane algorithm is worst-case O(n m^2) with n = minion count in
    # play and m = total archetype count. I think it's fine because
    # all of those numbers are small.
    var candidate_tribes = Archetype.all()
    for minion in minions:
        Util.filter_swap_in_place(candidate_tribes, func(tribe):
            if minion is CardType:
                return minion is MinionCardType and tribe in minion.get_base_archetypes()
            else:
                return minion.has_archetype(playing_field, tribe))
        if len(candidate_tribes) == 0:
            return [false, minion]
    return [true, null]


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # If we already have a mismatch, then Elvira will do nothing.
    var result_now = _do_all_minions_match(playing_field, Query.on(playing_field).minions(player).array())
    if not result_now[0]:
        return score

    # Figure out how much Morale will be gained.
    var total_damage_increase = 0
    for minion in Query.on(playing_field).minions(player).array():
        total_damage_increase += minion.card_type.get_level(playing_field, minion)
    score += total_damage_increase * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    # If we can play another Minion (while maintaining the tribal
    # ideology) before playing Elvira, we should do that first so that
    # Elvira has more effect.
    var evil_points_left = playing_field.get_stats(player).evil_points - self.get_star_cost()
    for card_in_hand in Query.on(playing_field).hand(player).array():
        if card_in_hand is MinionCardType and card_in_hand.get_star_cost() <= evil_points_left and _do_all_minions_match(playing_field, Query.on(playing_field).minions(player).array() + [card_in_hand])[0]:
            score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score
