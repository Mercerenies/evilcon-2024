extends MinionCardType


func get_id() -> int:
    return 210


func get_title() -> String:
    return "The King of Crime"


func get_text() -> String:
    return "Each turn, during your End Phase, your opponent's weakest Minion is converted to your side."


func get_picture_index() -> int:
    return 225


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_end_phase(playing_field, this_card) -> void:
    await super.on_end_phase(playing_field, this_card)

    var owner = this_card.owner
    if owner != playing_field.turn_player:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var chosen_minion = Query.on(playing_field).minions(CardPlayer.other(owner)).min()
    if chosen_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        var owner_minions_strip = playing_field.get_minion_strip(owner)
        var opponent_minions_strip = playing_field.get_minion_strip(CardPlayer.other(owner))
        var chosen_minion_index = opponent_minions_strip.cards().find_card(chosen_minion)
        await CardGameApi.move_card(playing_field, opponent_minions_strip, owner_minions_strip, {
            "source_index": chosen_minion_index,
        })
        chosen_minion.owner = this_card.owner
        await chosen_minion.card_type.on_enter_ownership(playing_field, chosen_minion)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # Assume the opponent is playing adversarial and will try to
    # summon a weak (1/1) Minion. So we only get +2 every turn (+1 to
    # our side and -1 to their side, totalling +2).
    score += 2 * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)

    if this_card.owner == player:
        return score

    # If the opponent controls King of Crime and we do NOT have a Cost
    # 1 Minion, it's a minor right order buff to play one and sabotage
    # King of Crime.
    if not Query.on(playing_field).minions(player).any(Query.cost().at_most(1)):
        if target_card_type is MinionCardType and target_card_type.get_star_cost() <= 1:
            score += priorities.of(LookaheadPriorities.MINOR_RIGHT_ORDER)

    return score


func ai_get_expected_remaining_score(playing_field, card) -> float:
    var score = super.ai_get_expected_remaining_score(playing_field, card)
    var morale = get_base_morale() if card == null else get_morale(playing_field, card)
    score += maxi(morale - 1, 0)  # -1 because The King of Crime brainwashes during the End Phase, not the Morale Phase.
    return score
