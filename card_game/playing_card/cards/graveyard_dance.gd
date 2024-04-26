extends EffectCardType


func get_id() -> int:
    return 96


func get_title() -> String:
    return "Graveyard Dance"


func get_text() -> String:
    return "Play all [icon]UNDEAD[/icon] UNDEAD Minions from your discard pile. Each Minion played in this way returns with 1 Morale."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 89


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner

    var discard_pile = playing_field.get_discard_pile(owner)
    var undead_cards_to_play = discard_pile.cards().card_array().filter(func (card_type):
        return card_type is MinionCardType and Archetype.UNDEAD in card_type.get_base_archetypes())
    undead_cards_to_play.reverse()  # Play from the top, not the bottom, first

    if len(undead_cards_to_play) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return

    for undead_card_type in undead_cards_to_play:
        # If playing one of the cards caused this card to be moved out
        # of the discard pile, then we can't resurrect it anymore. So
        # check here that the card is still in the discard pile, since
        # that might have changed since we first made the
        # undead_cards_to_play array.
        if discard_pile.cards().has_card(undead_card_type):
            var undead_card = await CardGameApi.resurrect_card(playing_field, owner, undead_card_type)
            if undead_card.card_type.get_morale(playing_field, undead_card) != 1:
                await Stats.set_morale(playing_field, undead_card, 1)
