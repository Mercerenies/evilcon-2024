extends EffectCardType


func get_id() -> int:
    return 119


func get_title() -> String:
    return "Boiling Pot of Water"


func get_text() -> String:
    return "Discard all [icon]PASTA[/icon] Minions from your hand; then draw one more card than the number of cards discarded. Limit 1 per deck."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 136


func get_rarity() -> int:
    return Rarity.UNCOMMON


func is_limited() -> bool:
    return true


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var cards_to_discard = (
        Query.on(playing_field).hand(owner)
        .filter(Query.by_archetype(Archetype.PASTA))
        .array()
    )
    for card in cards_to_discard:
        await CardGameApi.discard_card(playing_field, owner, card)
    await CardGameApi.draw_cards(playing_field, owner, len(cards_to_discard) + 1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var cards_to_discard = (
        Query.on(playing_field).hand(player)
        .count(Query.by_archetype(Archetype.PASTA))
    )
    score -= cards_to_discard * priorities.of(LookaheadPriorities.CARD_IN_HAND)

    var cards_in_hand = playing_field.get_hand(player).cards().card_count() - 1  # Subtract this card
    var max_hand_size = StatsCalculator.get_hand_limit(playing_field, player)
    var cards_to_draw = mini(cards_to_discard + 1, max_hand_size - cards_in_hand)
    score += cards_to_draw * priorities.of(LookaheadPriorities.EFFECT_DRAW)

    return score
