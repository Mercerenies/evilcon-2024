extends EffectCardType


func get_id() -> int:
    return 172


func get_title() -> String:
    return "Pollination"


func get_text() -> String:
    return "If you control at least one [icon]BEE[/icon] BEE Minion, then create a copy of your most powerful [icon]NATURE[/icon] NATURE Minion."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 167


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    if not _has_any_bees(playing_field, owner):
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var strongest_minion = _get_strongest_nature_minion(playing_field, owner)
    if strongest_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    await CardGameApi.copy_card(playing_field, owner, strongest_minion)


func _get_strongest_nature_minion(playing_field, owner):
    var nature_minions = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func(c): return c.has_archetype(playing_field, Archetype.NATURE))
    )
    return Util.max_by(nature_minions, CardEffects.card_power_less_than(playing_field))


func _has_any_bees(playing_field, owner) -> bool:
    var minions = playing_field.get_minion_strip(owner).cards().card_array()
    return minions.any(func(c): return c.has_archetype(playing_field, Archetype.BEE))


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    if not _has_any_bees(playing_field, player):
        # Effect fizzles and nothing happens.
        return score

    var strongest_nature_minion = _get_strongest_nature_minion(playing_field, player)
    if strongest_nature_minion == null:
        # Nothing to copy
        return score

    var remaining_value = strongest_nature_minion.card_type.ai_get_expected_remaining_score(playing_field, strongest_nature_minion)
    score += remaining_value
    return score
