extends EffectCardType


func get_id() -> int:
    return 141


func get_title() -> String:
    return "Brainwashing Ray"


func get_text() -> String:
    return "One random enemy Minion is converted to your side of the field."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 147


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var opponent = CardPlayer.other(this_card.owner)

    # Choose a random enemy Minion.
    var opponent_minions_strip = playing_field.get_minion_strip(opponent)
    var minions = opponent_minions_strip.cards().card_array()
    if len(minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return
    var chosen_minion = playing_field.randomness.choose(minions)
    var can_influence = chosen_minion.card_type.do_influence_check(playing_field, chosen_minion, this_card, false)
    if can_influence:
        var chosen_minion_index = opponent_minions_strip.cards().find_card(chosen_minion)
        var owner_minions_strip = playing_field.get_minion_strip(this_card.owner)
        await CardGameApi.move_card(playing_field, opponent_minions_strip, owner_minions_strip, {
            "source_index": chosen_minion_index,
        })
        chosen_minion.owner = this_card.owner
        await chosen_minion.card_type.on_enter_ownership(playing_field, chosen_minion)
    playing_field.emit_cards_moved()




func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var minions = playing_field.get_minion_strip(CardPlayer.other(player)).cards().card_array()
    if len(minions) == 0:
        # Nothing to do
        return score

    var numerator = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter(Query.influenced_by(self, player))
        .map_sum(Query.remaining_ai_value().value())
    )
    # Note: 2.0 times because we're removing it from the enemy AND
    # giving it to ourselves.
    score += (numerator / len(minions)) * 2.0 * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
