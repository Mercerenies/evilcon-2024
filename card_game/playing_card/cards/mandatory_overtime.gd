extends TimedCardType


func get_id() -> int:
    return 107


func get_title() -> String:
    return "Mandatory Overtime"


func get_text() -> String:
    return "Your [icon]HUMAN[/icon] HUMAN Minions with 1 Morale do not decrease Morale. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 131


func get_rarity() -> int:
    return Rarity.UNCOMMON


func do_morale_phase_check(playing_field, this_card, performing_card) -> bool:
    if not await super.do_morale_phase_check(playing_field, this_card, performing_card):
        return false
    if this_card.owner != performing_card.owner:
        return true
    if performing_card.card_type is MinionCardType and not performing_card.has_archetype(playing_field, Archetype.HUMAN):
        return true
    if performing_card.metadata[CardMeta.MORALE] != 1:
        return true
    await CardGameApi.highlight_card(playing_field, this_card)
    return false


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    var total_turns = get_total_turn_count()
    var low_morale_human_levels = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.HUMAN))
        .map_sum(func(playing_field, human_card):
            var extra_turns = maxi(0, total_turns - human_card.card_type.get_morale(playing_field, human_card) + 1)
            return extra_turns * human_card.card_type.get_level(playing_field, human_card))
    )
    score += low_morale_human_levels * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    var low_morale_human_levels = (
        Query.on(playing_field).minions(player)
        .filter([Query.by_archetype(Archetype.HUMAN), Query.morale().at_most(1)])
        .map_sum(Query.level().value())
    )
    score += low_morale_human_levels * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType) or not (Archetype.HUMAN in target_card_type.get_base_archetypes()):
        return score

    var remaining_turns = get_total_turn_count() - this_card.metadata.get(CardMeta.TURN_COUNTER, 0)

    var base_level = target_card_type.get_base_level()
    var base_morale = target_card_type.get_base_morale()
    if base_morale <= remaining_turns:
        score += base_level * priorities.of(LookaheadPriorities.FORT_DEFENSE) * (remaining_turns - base_morale + 1)

    return score
