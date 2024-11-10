extends TimedCardType


func get_id() -> int:
    return 93


func get_title() -> String:
    return "Call of Ectoplasm"


func get_text() -> String:
    return "During your End Phase, the top [icon]UNDEAD[/icon] UNDEAD card of your discard pile returns to the field with 1 Morale. Lasts 4 turns."


func get_total_turn_count() -> int:
    return 4


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 88


func get_rarity() -> int:
    return Rarity.RARE


func on_end_phase(playing_field, card) -> void:
    var owner = card.owner
    if owner == playing_field.turn_player:
        await CardGameApi.highlight_card(playing_field, card)
        var target = (
            Query.on(playing_field).discard_pile(owner)
            .find(Query.by_archetype(Archetype.UNDEAD))
        )
        if target != null:
            var undead_card = await CardGameApi.resurrect_card(playing_field, owner, target)
            if undead_card.card_type.get_morale(playing_field, undead_card) != 1:
                await Stats.set_morale(playing_field, undead_card, 1)
        else:
            Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    await super.on_end_phase(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    var all_targets_levels = (
        Query.on(playing_field).discard_pile(player)
        .filter(Query.by_archetype(Archetype.UNDEAD))
        .slice(- get_total_turn_count())
        .map_sum(Query.level().value())
    )
    score += all_targets_levels * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score



func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    # If we get an extra turn on Call of Ectoplasm, assume that we'll
    # be able to pull an UNDEAD Minion from the discard pile. The
    # average Level of an UNDEAD Minion, as of Nov 9, 2024, is 1.75
    # (This excludes Disembodied Soul, whose Level is difficult to
    # calculate). So assume we'll get an extra 1.75 damage from this.
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)
    score += 1.75 * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
