extends EffectCardType


func get_id() -> int:
    return 86


func get_title() -> String:
    return "King Cannoli"


func get_text() -> String:
    return "Discard your entire hand; your most powerful Minion gains Morale equal to the number of cards discarded; then exile King Cannoli."


func get_star_cost() -> int:
    return 8


func get_picture_index() -> int:
    return 90


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var was_hero_blocked = await _evaluate_effect(playing_field, card)
    if was_hero_blocked:
        # If this card's effect was fully negated (by a hostage card),
        # do not exile.
        await CardGameApi.destroy_card(playing_field, card)
    else:
        await CardGameApi.exile_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> bool:
    # Returns true if the effect was blocked by a Hero-blocking card.
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return true

    # Discard all cards from hand
    var hand_cards = playing_field.get_hand(owner).cards().card_array()
    for card_type in hand_cards:
        await CardGameApi.discard_card(playing_field, owner, card_type)

    # Find most powerful Minion
    var most_powerful_minion = CardEffects.most_powerful_minion(playing_field, owner)
    if most_powerful_minion == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        var can_influence = await most_powerful_minion.card_type.do_influence_check(playing_field, most_powerful_minion, card, false)
        if can_influence:
            await Stats.add_morale(playing_field, most_powerful_minion, len(hand_cards))

    return false
