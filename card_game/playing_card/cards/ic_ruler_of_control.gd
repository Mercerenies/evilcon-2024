extends EffectCardType


func get_id() -> int:
    return 204


func get_title() -> String:
    return "I.C. - Ruler of Control"


func get_text() -> String:
    return "Your opponent's most powerful Minion loses Morale equal to the number of Minions you control."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 219


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var own_minions_count = (
        Query.on(playing_field).minions(owner).count()
    )
    var enemy_target = CardEffects.most_powerful_minion(playing_field, CardPlayer.other(owner))
    if enemy_target == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        var can_influence = enemy_target.card_type.do_influence_check(playing_field, enemy_target, this_card, false)
        if can_influence:
            await Stats.add_morale(playing_field, enemy_target, - own_minions_count)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # Figure out how much Morale this will drain.
    var own_minions_count = (
        Query.on(playing_field).minions(player).count()
    )
    var enemy_target = CardEffects.most_powerful_minion(playing_field, CardPlayer.other(player))
    if enemy_target == null:
        return score

    var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, enemy_target, self, player)
    if not can_influence:
        return score

    var curr_morale = enemy_target.card_type.get_morale(playing_field, enemy_target)
    if curr_morale <= own_minions_count:
        score += enemy_target.card_type.ai_get_value_of_destroying(playing_field, enemy_target, priorities)
    else:
        var damage_lost = own_minions_count * enemy_target.card_type.get_level(playing_field, enemy_target)
        score += damage_lost * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    # If we can play another Minion before playing I.C., we should do
    # that first so that I.C. has more effect.
    var evil_points_left = playing_field.get_stats(player).evil_points - self.get_star_cost()
    for card_in_hand in Query.on(playing_field).hand(player).array():
        if card_in_hand is MinionCardType and card_in_hand.get_star_cost() <= evil_points_left:
            score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score
