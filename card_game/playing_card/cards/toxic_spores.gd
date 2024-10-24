extends EffectCardType


func get_id() -> int:
    return 169


func get_title() -> String:
    return "Toxic Spores"


func get_text() -> String:
    return "If you control at least one [icon]NATURE[/icon] NATURE Minion, your opponent's most powerful Minion loses 1 Level."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 165


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var opponent = CardPlayer.other(owner)

    if not _owner_has_nature_minion(playing_field, owner):
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })  # TODO All of these cards that require a card to be present on owner's side should use a different word than "target". Maybe "trigger"?
        return

    var target_minion = CardEffects.most_powerful_minion(playing_field, opponent)
    if target_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var can_influence = await target_minion.card_type.do_influence_check(playing_field, target_minion, this_card, false)
    if not can_influence:
        # Effect was blocked
        return

    await Stats.add_level(playing_field, target_minion, -1)


func _owner_has_nature_minion(playing_field, owner) -> bool:
    var minions = playing_field.get_minion_strip(owner).cards().card_array()
    return minions.any(func(c): return c.has_archetype(playing_field, Archetype.NATURE))
