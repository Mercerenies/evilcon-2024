extends EffectCardType


func get_id() -> int:
    return 119


func get_title() -> String:
    return "Boiling Pot of Water"


func get_text() -> String:
    return "Discard all [icon]PASTA[/icon] Minions from your hand; then draw one more card than the number of cards discarded."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 136


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var cards_to_discard = (
        playing_field.get_hand(owner).cards().card_array()
        .filter(_is_pasta_minion)
    )
    if len(cards_to_discard) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return
    for card in cards_to_discard:
        CardGameApi.discard_card(playing_field, owner, card)
    await CardGameApi.draw_cards(playing_field, owner, len(cards_to_discard) + 1)


func _is_pasta_minion(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.PASTA in archetypes
