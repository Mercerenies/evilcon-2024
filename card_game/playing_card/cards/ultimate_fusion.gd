extends EffectCardType

const Turducken = preload("res://card_game/playing_card/cards/turducken.gd")


func get_id() -> int:
    return 104


func get_title() -> String:
    return "Ultimate Fusion"


func get_text() -> String:
    return "Destroy a Chicken, Turkey, and Duck on your side of the field; if you do so, create a Turducken with +3 Level and immunity to enemy card effects."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 120


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    var tributes = _find_tribute_cards(playing_field, owner)
    if len(tributes) < 3:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return
    await _play_rotate_animation(playing_field, tributes)
    for tribute_card in tributes:
        # TODO Do we need to do influence checks here? If one of the
        # influence checks fails, I guess the whole fusion fails.
        await CardGameApi.destroy_card(playing_field, tribute_card)
    var turducken_card = await CardGameApi.create_card(playing_field, owner, Turducken.new())
    turducken_card.metadata[CardMeta.HAS_SPECIAL_IMMUNITY] = true
    playing_field.emit_cards_moved()
    await Stats.add_level(playing_field, turducken_card, 3)

func _play_animation_for_card(playing_field, tribute_card, promise) -> void:
    await CardGameApi.rotate_card(playing_field, tribute_card)
    promise.resolve()


func _play_rotate_animation(playing_field, tribute_cards: Array) -> void:
    var promises = tribute_cards.map(func (card):
        var promise = Promise.new()
        _play_animation_for_card(playing_field, card, promise)
        return promise)
    await Promise.async_all(promises)


func _find_tribute_cards(playing_field, owner):
    var matches = [
        _find_card_by_id(playing_field, owner, PlayingCardCodex.ID.CHICKEN),
        _find_card_by_id(playing_field, owner, PlayingCardCodex.ID.DUCK),
        _find_card_by_id(playing_field, owner, PlayingCardCodex.ID.TURKEY),
    ]
    return matches.filter(func (c): return c != null)


func _find_card_by_id(playing_field, owner, target_id):
    # On the offchance we find multiple matches (e.g. you have
    # multiple Turkeys in play), we take the weakest one for tribute.
    var minions_in_play = playing_field.get_minion_strip(owner).cards().card_array()
    var matching_minions = minions_in_play.filter(func (c): return c.card_type.get_id() == target_id)
    if len(matching_minions) == 0:
        return null
    else:
        return Util.min_by(matching_minions, CardEffects.card_power_less_than(playing_field))


func _ai_turducken_summon_value(priorities) -> float:
    var ai_value_of_card = 12.0  # 4 Level * 3 Morale
    return ai_value_of_card * (priorities.of(LookaheadPriorities.FORT_DEFENSE) + priorities.of(LookaheadPriorities.IMMUNITY))


func _ai_could_play_turducken_this_turn(playing_field, player: StringName) -> bool:
    var evil_points = playing_field.get_stats(player).evil_points
    var cards_needed = [PlayingCardCodex.ID.CHICKEN, PlayingCardCodex.ID.DUCK, PlayingCardCodex.ID.TURKEY, self.get_id()]
    var card_costs = [1, 2, 2, 3]
    for i in range(len(cards_needed)):
        var card_id = cards_needed[i]
        if Query.on(playing_field).minions(player).any(Query.by_id(card_id)):
            # Card is already on the field, so no change.
            pass
        elif Query.on(playing_field).hand(player).any(Query.by_id(card_id)):
            # Card would need to be played, so include its cost.
            evil_points -= card_costs[i]
        else:
            # Impossible to play this turn.
            return false
    return evil_points >= 0


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # If we can summon the Turducken, then we get the value of doing so
    var tributes = _find_tribute_cards(playing_field, player)
    if len(tributes) >= 3:
        score += _ai_turducken_summon_value(priorities)
        for tribute in tributes:
            score -= tribute.card_type.ai_get_value_of_destroying(playing_field, tribute, priorities)

    # This is probably overly-cautious, since Ultimate Fusion is
    # already -3.0 if it fizzles. But if we CAN do the combo in the
    # right order and simply choose not to, it's a wrong order
    # penalty.
    if len(tributes) < 3 and _ai_could_play_turducken_this_turn(playing_field, player):
        score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score


func ai_get_score_broadcasted_in_hand(playing_field, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted_in_hand(playing_field, player, priorities, target_card_type)

    var cards_needed = [PlayingCardCodex.ID.CHICKEN, PlayingCardCodex.ID.DUCK, PlayingCardCodex.ID.TURKEY]
    if not (target_card_type.get_id() in cards_needed):
        return score

    if _ai_could_play_turducken_this_turn(playing_field, player):
        score += priorities.of(LookaheadPriorities.RIGHT_ORDER)
    else:
        score -= priorities.of(LookaheadPriorities.MINOR_RIGHT_ORDER)
    return score
