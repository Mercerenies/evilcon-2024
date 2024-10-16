extends MinionCardType


func get_id() -> int:
    return 143


func get_title() -> String:
    return "Silent Clown"


func get_text() -> String:
    return "[font_size=12]Silent Clown is immune to enemy card effects. When Silent Clown expires, a random enemy non-[icon]CLOWN[/icon] CLOWN Minion is now of type [icon]CLOWN[/icon] CLOWN.[/font_size]"


func get_picture_index() -> int:
    return 146


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.NINJA]


func get_rarity() -> int:
    return Rarity.COMMON


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        await CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        await super.do_influence_check(playing_field, target_card, source_card, silently)
    )


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var opponent = CardPlayer.other(this_card.owner)
    await CardGameApi.highlight_card(playing_field, this_card)

    var enemy_targets = (
        playing_field.get_minion_strip(opponent).cards()
        .card_array()
        .filter(func (minion): return not minion.has_archetype(playing_field, Archetype.CLOWN))
    )

    if len(enemy_targets) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
            "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
        })
    else:
        var selected_target = playing_field.randomness.choose(enemy_targets)
        var can_influence = await selected_target.card_type.do_influence_check(playing_field, selected_target, this_card, false)
        if can_influence:
            var card_node = CardGameApi.find_card_node(playing_field, selected_target)
            Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
                "custom_label_text": Stats.CLOWNED_TEXT,
                "custom_label_color": Stats.CLOWNED_COLOR,
                "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
            })
            selected_target.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()
