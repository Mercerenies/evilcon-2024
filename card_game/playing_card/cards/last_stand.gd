extends EffectCardType


func get_id() -> int:
    return 120


func get_title() -> String:
    return "Last Stand"


func get_text() -> String:
    return "[font_size=12]Play the top Minion of your discard pile. That Minion has 1 Morale and is [icon]UNDEAD[/icon] UNDEAD. Exile that Minion when it is removed from the field. Limit 1 per deck.[/font_size]"


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 138


func get_rarity() -> int:
    return Rarity.RARE


func is_limited() -> bool:
    return true


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var discard_pile = playing_field.get_discard_pile(owner)
    await CardGameApi.highlight_card(playing_field, this_card)
    var target_card_type = Query.on(playing_field).discard_pile(owner).find(Query.is_minion)
    if target_card_type == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return
    var target_card = await CardGameApi.resurrect_card(playing_field, owner, target_card_type)
    if target_card.card_type.get_morale(playing_field, target_card) != 1:
        await Stats.set_morale(playing_field, target_card, 1)
    target_card.metadata[CardMeta.IS_DOOMED] = true
    target_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.UNDEAD]
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    var target_card_type = Query.on(playing_field).discard_pile(player).find(Query.is_minion)
    if target_card_type != null:
        score += target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
        score -= target_card_type.ai_get_expected_remaining_score(playing_field, null) * priorities.of(LookaheadPriorities.DOOMED_EXILE)

    return score
