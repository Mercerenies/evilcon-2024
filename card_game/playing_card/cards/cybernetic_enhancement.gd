extends EffectCardType


func get_id() -> int:
    return 167


func get_title() -> String:
    return "Cybernetic Enhancement"


func get_text() -> String:
    return "Your most powerful [icon]HUMAN[/icon] HUMAN Minion is now of type [icon]ROBOT[/icon] ROBOT."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 159


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var candidates = (
        playing_field.get_minion_strip(owner).cards().card_array()
        .filter(func(c): return c.has_archetype(playing_field, Archetype.HUMAN) and not c.has_archetype(playing_field, Archetype.ROBOT))
    )
    if len(candidates) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var most_powerful_candidate = Util.max_by(candidates, CardEffects.card_power_less_than(playing_field))
    var can_influence = most_powerful_candidate.card_type.do_influence_check(playing_field, most_powerful_candidate, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, most_powerful_candidate, PopupText.ROBOTED)
        most_powerful_candidate.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.ROBOT]
    playing_field.emit_cards_moved()
