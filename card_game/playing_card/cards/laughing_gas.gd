extends EffectCardType


func get_id() -> int:
    return 156


func get_title() -> String:
    return "Laughing Gas"


func get_text() -> String:
    return "All enemy Minions are now of type [icon]CLOWN[/icon] CLOWN."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 163


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner

    var enemy_minions = playing_field.get_minion_strip(CardPlayer.other(owner)).cards().card_array()
    if len(enemy_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    for minion in enemy_minions:
        await _try_to_clown(playing_field, this_card, minion)


func _try_to_clown(playing_field, this_card, target_card):
    var can_influence = target_card.card_type.do_influence_check(playing_field, target_card, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, target_card, PopupText.CLOWNED)
        target_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()
