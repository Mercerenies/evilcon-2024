extends MinionCardType


const TARGET_ARCHETYPES = [Archetype.FARM, Archetype.BEE, Archetype.NATURE, Archetype.TURTLE]


func get_id() -> int:
    return 202


func get_title() -> String:
    return "Ricky Riddle"


func get_text() -> String:
    return "[font_size=12]+1 Morale to all [icon]FARM[/icon] FARM, [icon]BEE[/icon] BEE, [icon]NATURE[/icon] NATURE, and [icon]TURTLE[/icon] TURTLE cards played while Ricky Riddle is in play, regardless of owner.[/font_size]"


func get_picture_index() -> int:
    return 216


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if not (played_card.card_type is MinionCardType):
        return
    if not (TARGET_ARCHETYPES.any(func (a): return played_card.has_archetype(playing_field, a))):
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        await Stats.add_morale(playing_field, played_card, 1)
    playing_field.emit_cards_moved()


func _ai_has_any_target_archetypes(card_type) -> bool:
    if not (card_type is MinionCardType):
        return false
    var card_archetypes = card_type.get_base_archetypes()
    for target_archetype in TARGET_ARCHETYPES:
        if target_archetype in card_archetypes:
            return true
    return false


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # If we are holding any relevant Minions in hand that we can ALSO
    # play this turn, then Ricky Riddle is an excellent move.
    var evil_points = playing_field.get_stats(player).evil_points
    for card_in_hand in playing_field.get_hand(player).cards().card_array():
        if not (card_in_hand is MinionCardType):
            continue
        if not _ai_has_any_target_archetypes(card_in_hand):
            continue
        if evil_points >= get_star_cost() + card_in_hand.get_star_cost():
            score += card_in_hand.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)

    # If anyone controls Ricky Riddle, add +1 the planned Morale of
    # the card to be played.
    if target_card_type is MinionCardType and _ai_has_any_target_archetypes(target_card_type):
        score += target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted_in_hand(playing_field, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted_in_hand(playing_field, player, priorities, target_card_type)

    # If Ricky Riddle is in the hand and we can afford to play both,
    # then we should play him BEFORE other cards that will be affected
    # by him.
    var evil_points = playing_field.get_stats(player).evil_points
    if target_card_type is MinionCardType and _ai_has_any_target_archetypes(target_card_type) and evil_points >= get_star_cost() + target_card_type.get_star_cost():
        score -= priorities.of(LookaheadPriorities.RIGHT_ORDER)

    return score
