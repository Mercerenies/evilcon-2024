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

    # Get the fully broadcasted score of all targets, so that we
    # include any benefits from Queen Bee or Venomatrix cards already
    # in play.
    score += (
        Query.on(playing_field).deck(player)
        .filter(Query.by_id(_valid_target_minions()))
        .map_sum(func(playing_field, card_type): return card_type.ai_get_score(playing_field, player, priorities) + card_type.get_star_cost() * priorities.of(LookaheadPriorities.EVIL_POINT))
    )

    return score
