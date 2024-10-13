extends EffectCardType


func get_id() -> int:
    return 120


func get_title() -> String:
    return "Last Stand"


func get_text() -> String:
    return "[font_size=12]Play the top Minion of your discard pile. That Minion has 1 Morale and is [icon]UNDEAD[/icon] UNDEAD. Exile that Minion when it is removed from the field for any reason.[/font_size]"


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 138


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var discard_pile = playing_field.get_discard_pile(owner)
    await CardGameApi.highlight_card(playing_field, this_card)
    var target_index = _find_minion_card_in_discard_pile(playing_field, owner)
    if target_index == null:
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return
    var target_card_type = discard_pile.cards().peek_card(target_index)
    var target_card = await CardGameApi.resurrect_card(playing_field, owner, target_card_type)
    if target_card.card_type.get_morale(playing_field, target_card) != 1:
        await Stats.set_morale(playing_field, target_card, 1)
    target_card.metadata[CardMeta.IS_DOOMED] = true
    target_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.UNDEAD]
    playing_field.emit_cards_moved()


func _find_minion_card_in_discard_pile(playing_field, owner: StringName):
    var discard_pile = playing_field.get_discard_pile(owner)
    return discard_pile.cards().find_card_reversed_if(func (card_type):
        return card_type is MinionCardType)
