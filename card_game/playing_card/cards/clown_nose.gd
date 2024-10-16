extends EffectCardType


func get_id() -> int:
    return 138


func get_title() -> String:
    return "Clown Nose"


func get_text() -> String:
    return "Your opponent's most powerful non-[icon]CLOWN[/icon] CLOWN Minion is now of type [icon]CLOWN[/icon] CLOWN."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 152


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var opponent = CardPlayer.other(this_card.owner)

    # Find opponent's most powerful non-Clown.
    var minions = (
        playing_field.get_minion_strip(opponent).cards()
        .card_array()
        .filter(func (minion): return not minion.has_archetype(playing_field, Archetype.CLOWN))
    )
    if len(minions) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return

    var most_powerful_minion = Util.max_by(minions, CardEffects.card_power_less_than(playing_field))
    var can_influence = await most_powerful_minion.card_type.do_influence_check(playing_field, most_powerful_minion, this_card, false)
    if not can_influence:
        return

    var target_card_node = CardGameApi.find_card_node(playing_field, most_powerful_minion)
    Stats.play_animation_for_stat_change(playing_field, target_card_node, 0, {
        "custom_label_text": Stats.CLOWNED_TEXT,
        "custom_label_color": Stats.CLOWNED_COLOR,
    })
    most_powerful_minion.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
