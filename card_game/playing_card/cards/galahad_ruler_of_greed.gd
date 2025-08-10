extends EffectCardType


func get_id() -> int:
    return 203


func get_title() -> String:
    return "Galahad - Ruler of Greed"


func get_text() -> String:
    return "Play the top three Cost 1 Minions from your deck to the field immediately."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 218


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = (
        Query.on(playing_field).deck(owner)
        .filter([Query.is_minion, Query.cost().exactly(1)])
        .array()
    )
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        # Play the top three
        for i in range(0, min(3, len(valid_target_minions))):
            var target_minion = valid_target_minions[i]
            await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # Figure out how many cards this will successfully play.
    var minion_count = (
        Query.on(playing_field).deck(player)
        .filter([Query.is_minion, Query.cost().exactly(1)])
        .count()
    )
    score += min(minion_count, 3) * priorities.of(LookaheadPriorities.EVIL_POINT)

    return score
