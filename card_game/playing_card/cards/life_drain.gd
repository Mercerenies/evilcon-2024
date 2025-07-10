extends EffectCardType


func get_id() -> int:
    return 182


func get_title() -> String:
    return "Life Drain"


func get_text() -> String:
    return "[font_size=12]Destroy your weakest non-[icon]DEMON[/icon] DEMON Minion. Your strongest [icon]DEMON[/icon] DEMON Minion gains Level and Morale equal to that of the destroyed Minion.[/font_size]"


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 189


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var tribute = _get_weakest_non_demon(playing_field, owner)
    var beneficiary = _get_strongest_demon(playing_field, owner)
    if tribute == null or beneficiary == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var can_influence = tribute.card_type.do_influence_check(playing_field, tribute, this_card, false)
    if can_influence:
        var tributed_level = tribute.card_type.get_level(playing_field, tribute)
        var tributed_morale = tribute.card_type.get_morale(playing_field, tribute)
        await CardGameApi.destroy_card(playing_field, tribute)
        await Stats.add_level(playing_field, beneficiary, tributed_level)
        await Stats.add_morale(playing_field, beneficiary, tributed_morale)


func _get_weakest_non_demon(playing_field, owner):
    var non_demons = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func(minion): return not minion.has_archetype(playing_field, Archetype.DEMON))
    )
    return Util.min_by(non_demons, CardEffects.card_power_less_than(playing_field))


func _get_strongest_demon(playing_field, owner):
    var demons = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func(minion): return minion.has_archetype(playing_field, Archetype.DEMON))
    )
    return Util.max_by(demons, CardEffects.card_power_less_than(playing_field))


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var tribute = _get_weakest_non_demon(playing_field, player)
    var beneficiary = _get_strongest_demon(playing_field, player)
    if tribute == null or beneficiary == null:
        return score  # Effect will fizzle if played.

    var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, tribute, self, player)
    if not can_influence:
        return score  # Effect is blocked

    # Sacrificing the remaining value of the tribute.
    score -= tribute.card_type.ai_get_value_of_destroying(playing_field, tribute, priorities)

    # Adding the increased value of the DEMON.
    var tribute_level = tribute.card_type.get_level(playing_field, tribute)
    var tribute_morale = tribute.card_type.get_morale(playing_field, tribute)
    var curr_level = beneficiary.card_type.get_level(playing_field, beneficiary)
    var curr_morale = beneficiary.card_type.get_morale(playing_field, beneficiary)
    var increased_fort_defense_damage = tribute_level * tribute_morale + tribute_level * curr_morale + curr_level * tribute_morale
    score += increased_fort_defense_damage * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score

# TODO Would be nice to be able to teach the AI how to
# play-then-immediately-Life-Drain a card for an extant DEMON Minion.
