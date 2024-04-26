extends TimedCardType


func get_id() -> int:
    return 93


func get_title() -> String:
    return "Call of Ectoplasm"


func get_text() -> String:
    return "During your End Phase, the top [icon]UNDEAD[/icon] UNDEAD card of your discard pile returns to the field with 1 Morale. Lasts 4 turns."


func get_total_turn_count() -> int:
    return 4


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 88


func get_rarity() -> int:
    return Rarity.RARE


func on_end_phase(playing_field, card) -> void:
    var owner = card.owner
    if owner == playing_field.turn_player:
        var discard_pile = playing_field.get_discard_pile(owner)
        await CardGameApi.highlight_card(playing_field, card)
        var target_index = _find_undead_card_in_discard_pile(playing_field, card.owner)
        if target_index != null:
            var undead_card_type = discard_pile.cards().peek_card(target_index)
            var undead_card = await CardGameApi.resurrect_card(playing_field, owner, undead_card_type)
            if undead_card.card_type.get_morale(playing_field, undead_card) != 1:
                await Stats.set_morale(playing_field, undead_card, 1)
        else:
            var card_node = CardGameApi.find_card_node(playing_field, card)
            Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
                "custom_label_text": Stats.NO_TARGET_TEXT,
                "custom_label_color": Stats.NO_TARGET_COLOR,
            })
    await super.on_end_phase(playing_field, card)


func _find_undead_card_in_discard_pile(playing_field, owner: StringName):
    var discard_pile = playing_field.get_discard_pile(owner)
    return discard_pile.cards().find_card_reversed_if(func (card_type):
        return card_type is MinionCardType and Archetype.UNDEAD in card_type.get_base_archetypes())
