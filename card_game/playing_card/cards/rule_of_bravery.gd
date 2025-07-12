extends EffectCardType


func get_id() -> int:
    return 193


func get_title() -> String:
    return "Rule of Bravery"


func get_text() -> String:
    return "If you control Rule 22, +1 Morale to all of your Minions."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 207


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, this_card) -> void:
    await super.on_play(playing_field, this_card)
    await _evaluate_effect(playing_field, this_card)
    await CardGameApi.destroy_card(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    await CardGameApi.highlight_card(playing_field, this_card)

    if not CardEffects.has_rule_22(playing_field, owner):
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var minions = Query.on(playing_field).minions(owner).array()

    if len(minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        for minion in minions:
            var can_influence = minion.card_type.do_influence_check(playing_field, minion, this_card, false)
            if can_influence:
                await Stats.add_morale(playing_field, minion, 1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    if not CardEffects.has_rule_22(playing_field, player):
        return score

    var defense_points = (
        Query.on(playing_field).minions(player)
        .filter(Query.influenced_by(self, player))
        .map_sum(Query.level().value())
    )
    score += defense_points * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
