extends TimedCardType


func get_id() -> int:
    return 185


func get_title() -> String:
    return "Farmer's Market"


func get_text() -> String:
    return "During your Standby Phase, summon a random [icon]FARM[/icon] FARM Minion of Cost at most 2 from your deck. Lasts 3 turns."


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 183


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_total_turn_count() -> int:
    return 3


func on_standby_phase(playing_field, this_card) -> void:
    if this_card.owner == playing_field.turn_player:
        await _evaluate_effect(playing_field, this_card)
    await super.on_standby_phase(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_valid_target_card_type)
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    # Prefer a Cost 2 Minion if one exists.
    if valid_target_minions.any(func (c): return c.get_star_cost() == 2):
        valid_target_minions = valid_target_minions.filter(func (c): return c.get_star_cost() == 2)

    var target_minion = playing_field.randomness.choose(valid_target_minions)
    await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)


func _is_valid_target_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes and card_type.get_star_cost() <= 2


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # This lasts 3 turns by default. It's pretty useless if there are
    # fewer than 3 FARM Minions left in the deck. (This calculation
    # ignores the possibility of reshuffling the discard pile into the
    # deck)
    var total_farm_minions = (
        Query.on(playing_field)
        .deck(player)
        .filter(Query.by_archetype(Archetype.FARM))
        .filter(Query.cost().at_most(2))
        .count()
    )
    var useful_turns = mini(total_farm_minions, get_total_turn_count())

    score += ai_get_score_per_turn(playing_field, player, priorities) * useful_turns
    return score


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    # Average value of FARM Minions in this deck.
    var number_of_farm_minions = _ai_query_relevant_farm_minions(playing_field, player).count()
    if number_of_farm_minions == 0:
        number_of_farm_minions = 1  # Avoid division by zero
    var value_of_farm_minions = _ai_query_relevant_farm_minions(playing_field, player).map_sum(Query.remaining_ai_value().value())
    score += priorities.of(LookaheadPriorities.EVIL_POINT) * float(value_of_farm_minions) / float(number_of_farm_minions)

    return score


func _ai_query_relevant_farm_minions(playing_field, player: StringName):
    return (
        Query.on(playing_field)
        .full_deck(player)
        .filter(Query.by_archetype(Archetype.FARM))
        .filter(Query.cost().at_most(2))
    )
