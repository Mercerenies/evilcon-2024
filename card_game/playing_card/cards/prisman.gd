extends EffectCardType


func get_id() -> int:
    return 92


func get_title() -> String:
    return "Prisman"


func get_text() -> String:
    return "Destroy your opponent's most powerful [icon]BOSS[/icon] BOSS Minion."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 127


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return

    # Destroy enemy's most powerful Boss Minion
    var target_minion = _get_most_powerful_boss_minion(playing_field, CardPlayer.other(owner))
    if target_minion == null:
        # No Boss minions in play
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


func _get_most_powerful_boss_minion(playing_field, owner):
    var minions = CardGameApi.get_minions_in_play(playing_field)
    minions = minions.filter(func (minion): return minion.owner == owner && minion.has_archetype(playing_field, Archetype.BOSS))
    if len(minions) < 1:
        return null
    return Util.max_by(minions, CardEffects.card_power_less_than(playing_field))
