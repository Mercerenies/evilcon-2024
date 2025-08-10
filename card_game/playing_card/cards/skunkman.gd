extends MinionCardType


func get_id() -> int:
    return 186


func get_title() -> String:
    return "Skunkman"


func get_text() -> String:
    return "When Skunkman is played, your opponent discards all Hero cards currently in their hand."


func get_picture_index() -> int:
    return 197


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.NATURE, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var opponent = CardPlayer.other(card.owner)

    await CardGameApi.highlight_card(playing_field, card)
    var cards_to_discard = (
        playing_field.get_hand(opponent).cards().card_array()
        .filter(func(c): return c is EffectCardType and c.is_hero())
    )
    if len(cards_to_discard) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return
    for target_card in cards_to_discard:
        await CardGameApi.discard_card(playing_field, opponent, target_card)
    await CardEffects.broadcast_discards(playing_field, opponent, cards_to_discard)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Assume that the opponent has 2 Hero cards in their deck. Thus,
    # every card held in hand has a 2 / 20, or 0.1, chance of being a
    # Hero card.
    var opponent = CardPlayer.other(player)
    var enemy_cards_in_hand = Query.on(playing_field).hand(opponent).count()
    score += enemy_cards_in_hand * 0.1 * priorities.of(LookaheadPriorities.CARD_IN_HAND)
    score += CardEffects.do_hypothetical_broadcast_discards(playing_field, player, opponent, ceil(enemy_cards_in_hand * 0.1), priorities)

    return score
