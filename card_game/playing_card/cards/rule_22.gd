extends EffectCardType


func get_id() -> int:
    return 191


func get_title() -> String:
    return "Rule 22"


func get_text() -> String:
    return "During your End Phase, if you control no [icon]SHAPE[/icon] SHAPE Minions, destroy this card. Limit 1 per deck."


func get_star_cost() -> int:
    return 8


func get_picture_index() -> int:
    return 204


func get_rarity() -> int:
    return Rarity.RARE


func is_ongoing() -> bool:
    return true


func is_limited() -> bool:
    return true


func on_end_phase(playing_field, this_card) -> void:
    await super.on_end_phase(playing_field, this_card)
    if this_card.owner == playing_field.turn_player:
        if not Query.on(playing_field).minions(this_card.owner).any(Query.by_archetype(Archetype.SHAPE)):
            await CardGameApi.highlight_card(playing_field, this_card)
            await CardGameApi.destroy_card(playing_field, this_card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # If we currently control no Shape Minions, then this card will
    # fizzle immediately, so don't bother.
    if not Query.on(playing_field).minions(player).any(Query.by_archetype(Archetype.SHAPE)):
        return score

    # Value of playing Rule 22 is entirely up to the particular AI
    # (it's orthogonal to all other priorities).
    score += priorities.of(LookaheadPriorities.RULE_22)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # If we control Rule 22 and no Shape Minions, we need to
    # prioritize feeding it a Shape Minion.
    if target_card_type is MinionCardType and Archetype.SHAPE in target_card_type.get_base_archetypes():
        if not Query.on(playing_field).minions(player).any(Query.by_archetype(Archetype.SHAPE)):
            # Rule 22 will expire. NOT playing this now would suffer a
            # wrong-order combo penalty.
            score += priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score
