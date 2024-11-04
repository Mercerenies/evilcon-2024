extends TimedCardType


func get_id() -> int:
    return 162


func get_title() -> String:
    return "Bull Market"


func get_text() -> String:
    return "All [icon]HUMAN[/icon] HUMAN Minions played while this card is in play start with +1 Morale. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 158


func get_rarity() -> int:
    return Rarity.RARE


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if not played_card.has_archetype(playing_field, Archetype.HUMAN):
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        await Stats.add_morale(playing_field, played_card, 1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # Consider all of the HUMAN Minions in our hand right now. Here,
    # we assume that we will be able to play all HUMAN Minions
    # currently in our hand by the time Bull Market expires.
    var humans_in_hand = (
        Query.on(playing_field).hand(player)
        .filter(Query.by_archetype(Archetype.HUMAN))
        .map_sum(Query.level().value())
    )
    score += humans_in_hand * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    # HUMAN Minions are pretty common. Assume the opponent has one in
    # their hand. See ai_get_score_per_turn comment for justification
    # on the 1.7 multiplier.
    score -= 1.7 * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    # If Bull Market lasts an extra turn, assume we'll manage to get
    # one more HUMAN out there. The average Level of a Minion (as of
    # Nov 2, 2024) is 1.7, so assume that HUMAN will deal 1.7 extra
    # damage.
    score += 1.7 * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if not (target_card_type is MinionCardType) or not (Archetype.HUMAN in target_card_type.get_base_archetypes()):
        return score

    # Playing a HUMAN now will result in +1 Morale to that HUMAN.
    var base_level = target_card_type.get_base_level()
    score += base_level * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
