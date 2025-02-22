extends EffectCardType


func get_id() -> int:
    return 169


func get_title() -> String:
    return "Toxic Spores"


func get_text() -> String:
    return "If you control at least one [icon]NATURE[/icon] NATURE Minion, your opponent's most powerful Minion loses 1 Level."


func get_star_cost() -> int:
    return 1


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
        # TODO All of these cards that require a card to be present on owner's side should use a different word than "target". Maybe "trigger"? Maybe "Failed"?
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var target_minion = CardEffects.most_powerful_minion(playing_field, opponent)
    if target_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var can_influence = target_minion.card_type.do_influence_check(playing_field, target_minion, this_card, false)
    if not can_influence:
        # Effect was blocked
        return

    await Stats.add_level(playing_field, target_minion, -1)


func _owner_has_nature_minion(playing_field, owner) -> bool:
    var minions = playing_field.get_minion_strip(owner).cards().card_array()
    return minions.any(func(c): return c.has_archetype(playing_field, Archetype.NATURE))


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    if not _owner_has_nature_minion(playing_field, player):
        # This card will have no effect.
        return score

    var target_minion = CardEffects.most_powerful_minion(playing_field, player)
    var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, target_minion, self, player)
    if can_influence and target_minion.card_type.get_level(playing_field, target_minion) > 0:
        score += target_minion.card_type.get_morale(playing_field, target_minion) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
