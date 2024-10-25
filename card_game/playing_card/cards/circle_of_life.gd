extends EffectCardType


func get_id() -> int:
    return 121


func get_title() -> String:
    return "Circle of Life"


func get_text() -> String:
    return "Move all [icon]FARM[/icon] FARM Minions from your discard pile to your deck; then shuffle your deck."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 140


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var discard_pile = playing_field.get_discard_pile(owner)
    var deck = playing_field.get_deck(owner)

    var cards_to_return = discard_pile.cards().card_array().filter(_is_farm_minion)
    if len(cards_to_return) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    for card in cards_to_return:
        await CardGameApi.move_card_from_discard_to_deck(playing_field, owner, card)
    deck.cards().shuffle()
    playing_field.emit_cards_moved()


func _is_farm_minion(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes
