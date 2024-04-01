extends EffectCardType


func get_id() -> int:
    return 59


func get_title() -> String:
    return "Plumberman"


func get_text() -> String:
    return "Destroy your opponent's most powerful Minion."


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 71


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return

    # Destroy enemy's most powerful Minion
    var target_minion = CardEffects.most_powerful_minion(playing_field, CardPlayer.other(owner))
    if target_minion == null:
        # No minions in play
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return

    var can_influence = await target_minion.card_type.do_influence_check(playing_field, target_minion, card, false)
    if not can_influence:
        # Effect was blocked
        return

    await CardGameApi.destroy_card(playing_field, target_minion)
