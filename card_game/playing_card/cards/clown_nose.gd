extends EffectCardType


func get_id() -> int:
    return 138


func get_title() -> String:
    return "Clown Nose"


func get_text() -> String:
    return "Your opponent's most powerful non-[icon]CLOWN[/icon] CLOWN Minion is now of type [icon]CLOWN[/icon] CLOWN."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 152


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var opponent = CardPlayer.other(this_card.owner)

    # Find opponent's most powerful non-Clown.
    var most_powerful_minion = (
        Query.on(playing_field).minions(opponent)
        .filter(Query.not_(Query.by_archetype(Archetype.CLOWN)))
        .max()
    )
    if most_powerful_minion == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var can_influence = most_powerful_minion.card_type.do_influence_check(playing_field, most_powerful_minion, this_card, false)
    if not can_influence:
        return

    Stats.show_text(playing_field, most_powerful_minion, PopupText.CLOWNED)
    most_powerful_minion.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)
    var opponent = CardPlayer.other(player)

    var most_powerful_minion = (
        Query.on(playing_field).minions(opponent)
        .filter(Query.not_(Query.by_archetype(Archetype.CLOWN)))
        .max()
    )
    if most_powerful_minion != null:
        var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, most_powerful_minion, self, player)
        if can_influence:
            score += priorities.of(LookaheadPriorities.CLOWNING)

    return score
