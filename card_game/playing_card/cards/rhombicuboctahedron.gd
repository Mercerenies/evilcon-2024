extends EffectCardType


func get_id() -> int:
    return 83


func get_title() -> String:
    return "Rhombicuboctahedron"


func get_text() -> String:
    return "Destroy all opponent Minions with 1 Morale."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 114


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _do_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _do_effect(playing_field, card) -> void:
    var owner = card.owner

    var opponent_minions_to_destroy = (
        Query.on(playing_field).minions(CardPlayer.other(owner))
        .filter(Query.morale().at_most(1))
        .array()
    )
    if len(opponent_minions_to_destroy) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        for minion in opponent_minions_to_destroy:
            var can_influence = minion.card_type.do_influence_check(playing_field, minion, card, false)
            if can_influence:
                await CardGameApi.destroy_card(playing_field, minion)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var opponent_minion_values = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter([Query.morale().at_most(1), Query.influenced_by(self, player)])
        .map_sum(Query.remaining_ai_value().value())
    )
    score += opponent_minion_values * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
