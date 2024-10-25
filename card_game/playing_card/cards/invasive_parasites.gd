extends EffectCardType


func get_id() -> int:
    return 157


func get_title() -> String:
    return "Invasive Parasites"


func get_text() -> String:
    return "[font_size=12]During your End Phase, destroy your weakest [icon]NATURE[/icon] NATURE Minion, then destroy a random enemy Minion. If you have no such Minions, destroy this card.[/font_size]"


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 164


func get_rarity() -> int:
    return Rarity.RARE


func on_end_phase(playing_field, this_card) -> void:
    if this_card.owner == playing_field.turn_player:
        await _try_to_perform_effect(playing_field, this_card)
    await super.on_end_phase(playing_field, this_card)


func _try_to_perform_effect(playing_field, this_card) -> void:
    var owner = this_card.owner

    await CardGameApi.highlight_card(playing_field, this_card)

    var friendly_nature_minions = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func(c): return c.has_archetype(playing_field, Archetype.NATURE))
    )
    if len(friendly_nature_minions) == 0:
        await CardGameApi.destroy_card(playing_field, this_card)
        return

    friendly_nature_minions.sort_custom(CardEffects.card_power_less_than(playing_field))
    var minion_to_destroy = friendly_nature_minions[0]
    var can_tribute = await minion_to_destroy.card_type.do_influence_check(playing_field, minion_to_destroy, this_card, false)
    if not can_tribute:
        return

    await CardGameApi.destroy_card(playing_field, minion_to_destroy)
    var enemy_minions = (
        playing_field.get_minion_strip(CardPlayer.other(owner))
        .cards().card_array()
    )
    if len(enemy_minions) == 0:
        # No minions in play
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var target_enemy_minion = playing_field.randomness.choose(enemy_minions)
    var can_destroy = await target_enemy_minion.card_type.do_influence_check(playing_field, target_enemy_minion, this_card, false)
    if can_destroy:
        await CardGameApi.destroy_card(playing_field, target_enemy_minion)
