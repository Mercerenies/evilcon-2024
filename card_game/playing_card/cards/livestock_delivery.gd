extends EffectCardType


func get_id() -> int:
    return 183


func get_title() -> String:
    return "Livestock Delivery"


func get_text() -> String:
    return "Summon the top [icon]FARM[/icon] FARM Minion from your deck to the field."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 185


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_farm_card_type)
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        # Choose a target minion and play
        var target_minion = valid_target_minions[-1]
        await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)


func _is_farm_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # We know what FARM Minions are in our deck but not the order. So
    # find the average value.
    var farm_minion_count = _ai_query_farm_minions_in_deck(playing_field, player).count()
    if farm_minion_count == 0:
        farm_minion_count = 1  # Avoid division by zero
    var farm_minion_value = _ai_query_farm_minions_in_deck(playing_field, player).map_sum(Query.remaining_ai_value().value())
    var avg_value = float(farm_minion_value) / float(farm_minion_count)
    score += avg_value * priorities.of(LookaheadPriorities.EVIL_POINT)

    return score


func _ai_query_farm_minions_in_deck(playing_field, player: StringName):
    return Query.on(playing_field).deck(player).filter(Query.by_archetype(Archetype.FARM))
