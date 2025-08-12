extends EffectCardType


func get_id() -> int:
    return 188


func get_title() -> String:
    return "Wild Card"


func get_text() -> String:
    return "Your most powerful Minion now belongs to every tribe. ([icon]HUMAN[/icon] HUMAN, [icon]NATURE[/icon] NATURE, etc.)"


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 208


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var non_wilds = (
        playing_field.get_minion_strip(owner).cards().card_array()
        .filter(func(c): return not c.metadata.get(CardMeta.WILDCARD, false))
    )
    if len(non_wilds) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var most_powerful_non_wild = Util.max_by(non_wilds, CardEffects.card_power_less_than(playing_field))
    var can_influence = most_powerful_non_wild.card_type.do_influence_check(playing_field, most_powerful_non_wild, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, most_powerful_non_wild, PopupText.WILDED)
        most_powerful_non_wild.metadata[CardMeta.WILDCARD] = true
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var non_wilds = (
        playing_field.get_minion_strip(player).cards().card_array()
        .filter(func(c): return not c.metadata.get(CardMeta.WILDCARD, false))
    )
    if len(non_wilds) == 0:
        return score

    var most_powerful_non_wild = Util.max_by(non_wilds, CardEffects.card_power_less_than(playing_field))
    var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, most_powerful_non_wild, self, player)
    if can_influence:
        score += priorities.of(LookaheadPriorities.WILDING)
    return score
