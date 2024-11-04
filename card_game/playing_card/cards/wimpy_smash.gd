extends EffectCardType

func get_id() -> int:
    return 161


func get_title() -> String:
    return "Wimpy Smash!"


func get_text() -> String:
    return "If you control Wimpy, +3 Level to Wimpy. Or +4 Level to Wimpy if this is not the first Wimpy Smash! used on that Minion."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 182


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var target_minion = _find_wimpy(playing_field, owner)
    if target_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return
    var can_influence = target_minion.card_type.do_influence_check(playing_field, target_minion, this_card, false)
    if can_influence:
        var level_up_amount = 4 if _is_wimpy_powered(target_minion) else 3
        await Stats.add_level(playing_field, target_minion, level_up_amount)
        target_minion.metadata[CardMeta.WIMPY_SMASHING] = true
    playing_field.emit_cards_moved()


func _find_wimpy(playing_field, owner):
    var wimpy_id = PlayingCardCodex.ID.WIMPY
    var wimpys = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func(c): return c.card_type.get_id() == wimpy_id)
    )
    if len(wimpys) == 0:
        return null
    var powered_index = Util.find_if(wimpys, _is_wimpy_powered)
    return wimpys[powered_index if powered_index != null else 0]


func _is_wimpy_powered(wimpy):
    return wimpy.metadata.get(CardMeta.WIMPY_SMASHING, false)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    var target = _find_wimpy(playing_field, player)
    if target != null:
        var level_up_amount = 4 if _is_wimpy_powered(target) else 3
        var morale = target.card_type.get_morale(playing_field, target)
        score += level_up_amount * morale * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
