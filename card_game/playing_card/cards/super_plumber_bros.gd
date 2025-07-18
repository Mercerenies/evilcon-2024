extends EffectCardType

const Plumberman = preload("res://card_game/playing_card/cards/plumberman.gd")
const PlumbermansBrother = preload("res://card_game/playing_card/cards/plumbermans_brother.gd")


func get_id() -> int:
    return 178


func get_title() -> String:
    return "Super Plumber Bros"


func get_text() -> String:
    return "Discard Plumberman and Plumberman's Brother from your hand; if you do, then destroy your opponent's three most powerful Minions."


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 188


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    var target_cards = _find_target_cards(playing_field, owner)
    if target_cards == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return
    for target_card in target_cards:
        await CardGameApi.discard_card(playing_field, owner, target_card)

    # Destroy 3 most powerful minions.
    var minions = playing_field.get_minion_strip(CardPlayer.other(owner)).cards().card_array()
    if len(minions) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return
    minions.sort_custom(CardEffects.card_power_less_than(playing_field))

    var minions_to_destroy = minions.slice(-3)
    minions_to_destroy.reverse()  # Destroy the strongest one first, just to make it look more natural.
    for target_minion in minions_to_destroy:
        var can_influence = target_minion.card_type.do_influence_check(playing_field, target_minion, card, false)
        if can_influence:
            await CardGameApi.destroy_card(playing_field, target_minion)


func _find_target_cards(playing_field, owner):
    var hand = playing_field.get_hand(owner).cards()
    var plumberman = hand.find_card_if(func (c): return c.get_id() == Plumberman.new().get_id())
    var plumbermans_brother = hand.find_card_if(func (c): return c.get_id() == PlumbermansBrother.new().get_id())
    if plumberman == null or plumbermans_brother == null:
        return null
    else:
        return [hand.peek_card(plumberman), hand.peek_card(plumbermans_brother)]


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var plumbers = _find_target_cards(playing_field, player)
    if plumbers == null:
        return score  # Effect will fizzle.

    var minions = playing_field.get_minion_strip(CardPlayer.other(player)).cards().card_array()
    minions.sort_custom(CardEffects.card_power_less_than(playing_field))
    var minions_to_destroy = minions.slice(-3)
    for minion in minions_to_destroy:
        var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, minion, self, player)
        if can_influence:
            var value_of_target = minion.card_type.ai_get_expected_remaining_score(playing_field, minion)
            score += value_of_target * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted_in_hand(playing_field, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted_in_hand(playing_field, player, priorities, target_card_type)

    if not (target_card_type.get_id() in [PlayingCardCodex.ID.PLUMBERMAN, PlayingCardCodex.ID.PLUMBERMANS_BROTHER]):
        return score

    # Minor wrong-order penalty
    score -= priorities.of(LookaheadPriorities.MINOR_RIGHT_ORDER)

    return score
