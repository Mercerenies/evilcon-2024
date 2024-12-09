extends TimedCardType


func get_id() -> int:
    return 170


func get_title() -> String:
    return "Circus Tent"


func get_text() -> String:
    return "Minions of Cost 2 or less played by your opponent are now of type [icon]CLOWN[/icon] CLOWN. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 66


func get_rarity() -> int:
    return Rarity.COMMON


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if this_card.owner == played_card.owner:
        return
    if played_card.card_type.get_star_cost() > 2:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, played_card, PopupText.CLOWNED)
        played_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)
    # As of Dec 9, 2024, the average EP cost of a playing card is 3.2,
    # so assume that the opponent is playing 2 or 3 cards per turn.
    #
    # Case I: If the opponent plays 2 cards per turn, it's likely that
    # both are between Cost 3 to 5 (there's a small chance of a 6-2 or
    # 7-1 split). In this case, we usually don't benefit from Circus
    # Tent.
    #
    # Case II: If the opponent plays 3, the most likely split is
    # 2-3-3, so we get one benefit per turn.
    #
    # This should put our benefit at 0.5 * CLOWNING. However, this
    # doesn't take into account effect cards. If the opponent plays
    # effect cards, then the Minions they play will be cheaper. Assume
    # one effect card per turn, which will likely (again, all of this
    # is a rough approximation) reduce a Minion to within our score
    # boundaries, putting us at 1.5 * CLOWNING per turn.
    score += 1.5 * priorities.of(LookaheadPriorities.CLOWNING)
    return score
