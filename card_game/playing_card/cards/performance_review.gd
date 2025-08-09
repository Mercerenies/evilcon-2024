extends EffectCardType


func get_id() -> int:
    return 195


func get_title() -> String:
    return "Performance Review"


func get_text() -> String:
    return "Your most powerful [icon]HUMAN[/icon] HUMAN Minion gains +2 Level but loses 1 Morale."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 222


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var owner = card.owner

    # Find owner's most powerful Human.
    var most_powerful_human = (
        Query.on(playing_field).minions(owner)
        .filter(Query.by_archetype(Archetype.HUMAN))
        .max()
    )
    await CardGameApi.highlight_card(playing_field, card)
    if most_powerful_human == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        var can_influence = most_powerful_human.card_type.do_influence_check(playing_field, most_powerful_human, card, false)
        if can_influence:
            await Stats.add_level(playing_field, most_powerful_human, 2, {
                "offset": Stats.CARD_MULTI_UI_OFFSET,
            })
            await Stats.add_morale(playing_field, most_powerful_human, -1)  # Note: Can cause expiration!
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    # TODO The interaction with Maxwell Sterling is really powerful;
    # can we get the AI to see that?
    var score = super.ai_get_score(playing_field, player, priorities)

    # Find owner's most powerful Human.
    var most_powerful_human = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.HUMAN))
        .max()
    )
    if most_powerful_human != null:
        var current_level = most_powerful_human.card_type.get_level(playing_field, most_powerful_human)
        var current_morale = most_powerful_human.card_type.get_morale(playing_field, most_powerful_human)

        if current_morale == 1:
            # Target Minion will be destroyed.
            score -= most_powerful_human.card_type.ai_get_value_of_destroying(playing_field, most_powerful_human, priorities)
        else:
            var added_fort_damage = 2 * current_morale - current_level - 2
            score += added_fort_damage * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
