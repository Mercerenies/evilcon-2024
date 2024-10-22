extends EffectCardType


func get_id() -> int:
    return 166


func get_title() -> String:
    return "Forbidden Fruit"


func get_text() -> String:
    return "Your most powerful non-[icon]DEMON[/icon] DEMON Minion is now of type [icon]DEMON[/icon] DEMON."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 174


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var non_demons = (
        playing_field.get_minion_strip(owner).cards().card_array()
        .filter(func(c): return not c.has_archetype(playing_field, Archetype.DEMON))
    )
    if len(non_demons) == 0:
        # No minions in play
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return

    var most_powerful_non_demon = Util.max_by(non_demons, CardEffects.card_power_less_than(playing_field))
    var can_influence = await most_powerful_non_demon.card_type.do_influence_check(playing_field, most_powerful_non_demon, this_card, false)
    if can_influence:
        var card_node = CardGameApi.find_card_node(playing_field, most_powerful_non_demon)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.DEMONED_TEXT,
            "custom_label_color": Stats.DEMONED_COLOR,
        })
        most_powerful_non_demon.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.DEMON]
    playing_field.emit_cards_moved()
