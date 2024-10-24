extends EffectCardType

const Wimpy = preload("res://card_game/playing_card/cards/wimpy.gd")


func get_id() -> int:
    return 161


func get_title() -> String:
    return "Wimpy Smash!"


func get_text() -> String:
    return "If you control Wimpy, +2 Level to Wimpy. Or +4 Level to Wimpy if this is not the first Wimpy Smash! used on that Minion."


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
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
            "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
        })
        return
    var can_influence = await target_minion.card_type.do_influence_check(playing_field, target_minion, this_card, false)
    if can_influence:
        var level_up_amount = 4 if _is_wimpy_powered(target_minion) else 2
        await Stats.add_level(playing_field, target_minion, level_up_amount)
        target_minion.metadata[CardMeta.WIMPY_SMASHING] = true
    playing_field.emit_cards_moved()


func _find_wimpy(playing_field, owner):
    var wimpy_id = Wimpy.new().get_id()
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
