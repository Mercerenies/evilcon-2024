extends TimedCardType


func get_id() -> int:
    return 137


func get_title() -> String:
    return "Library of Alexandria"


func get_text() -> String:
    return "[icon]HUMAN[/icon] HUMAN Minions do not decrease Morale during the Morale Phase, regardless of owner. Lasts 1 turn."


func get_total_turn_count() -> int:
    return 1


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 151


func get_rarity() -> int:
    return Rarity.RARE


func do_morale_phase_check(playing_field, this_card, performing_card) -> bool:
    if not await super.do_morale_phase_check(playing_field, this_card, performing_card):
        return false
    if performing_card.card_type is MinionCardType and performing_card.has_archetype(playing_field, Archetype.HUMAN):
        await CardGameApi.highlight_card(playing_field, this_card)
        return false
    return true


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    var friendly_human_levels = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.HUMAN))
        .map_sum(Query.level().value())
    )
    var enemy_human_levels = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter(Query.by_archetype(Archetype.HUMAN))
        .map_sum(Query.level().value())
    )
    score += (friendly_human_levels - enemy_human_levels) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if not (target_card_type is MinionCardType) or not (Archetype.HUMAN in target_card_type.get_base_archetypes()):
        return score

    var remaining_turns = get_total_turn_count() - this_card.metadata.get(CardMeta.TURN_COUNTER, 0)
    if this_card.owner != player:
        remaining_turns -= 1  # This card will count down before our next Morale Phase triggers.

    var base_level = target_card_type.get_base_level()
    score += base_level * priorities.of(LookaheadPriorities.FORT_DEFENSE) * remaining_turns

    return score
