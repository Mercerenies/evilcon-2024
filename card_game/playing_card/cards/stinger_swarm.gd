extends EffectCardType


func get_id() -> int:
    return 152


func get_title() -> String:
    return "Stinger Swarm"


func get_text() -> String:
    return "Summon all Busy Bee and Worker Bee Minions from your deck to the field immediately."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 161


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var cards_to_summon = (
        Query.on(playing_field).deck(owner)
        .filter(Query.by_id(_valid_target_minions()))
        .array()
    )
    if len(cards_to_summon) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    for target_card in cards_to_summon:
        await CardGameApi.play_card_from_deck(playing_field, owner, target_card)


func _valid_target_minions():
    return [PlayingCardCodex.ID.BUSY_BEE, PlayingCardCodex.ID.WORKER_BEE]


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # Worker Bee and Busy Bee are both 1/1 Minions, so each such
    # Minion counts as 1.0 * FORT_DEFENSE score.
    var targets = Query.on(playing_field).deck(player).count(Query.by_id(_valid_target_minions()))
    score += targets * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
