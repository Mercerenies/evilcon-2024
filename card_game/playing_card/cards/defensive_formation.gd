extends TimedCardType


func get_id() -> int:
    return 176


func get_title() -> String:
    return "Defensive Formation"


func get_text() -> String:
    return "[font_size=12]Your [icon]TURTLE[/icon] TURTLE Minions do not attack. If you control any such Minions, then enemy Minions deal no damage to your base. Lasts 1 turn. Limit 1 per deck.[/font_size]"


func is_limited() -> bool:
    return true


func get_total_turn_count() -> int:
    return 1


func get_star_cost() -> int:
    return 6


func get_picture_index() -> int:
    return 173


func get_rarity() -> int:
    return Rarity.RARE


func do_attack_phase_check(playing_field, this_card, attacking_card) -> bool:
    if attacking_card.owner == this_card.owner and attacking_card.has_archetype(playing_field, Archetype.TURTLE):
        Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
            "offset": 1,
        })
        return false
    return super.do_attack_phase_check(playing_field, this_card, attacking_card)


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if not _owner_has_any_turtles(playing_field, this_card.owner):
        # Owner has no Turtles, so do nothing.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player as
        # the Defensive Formation
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    await CardGameApi.highlight_card(playing_field, this_card)

    var can_influence = attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
    if can_influence:  # TODO Consider if we can show this in the UI better, it's confusing right now
        Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
            "offset": 1,
        })
        return -99999

    return super.augment_attack_damage(playing_field, this_card, attacking_card)


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)
    if not _owner_has_any_turtles(playing_field, player):
        # No turtles, no effect
        return score
    score += _ai_get_score_for_extra_turn(playing_field, player, priorities)
    return score


func _ai_get_score_for_extra_turn(playing_field, player: StringName, priorities) -> float:
    var score = 0.0
    # Skips an attack from each Minion every turn.
    for minion in Query.on(playing_field).minions(CardPlayer.other(player)).array():
        var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, minion, self, player)
        if can_influence:
            score += minion.card_type.get_level(playing_field, minion) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    # Blocks attacks from your own TURTLEs every turn.
    for minion in Query.on(playing_field).minions(player).array():
        if minion.has_archetype(playing_field, Archetype.TURTLE):
            score -= minion.card_type.get_level(playing_field, minion) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func _owner_has_any_turtles(playing_field, owner) -> bool:
    var minions = playing_field.get_minion_strip(owner).cards().card_array()
    return minions.any(func(c): return c.has_archetype(playing_field, Archetype.TURTLE))


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)

    if this_card.owner == player:
        score += _ai_get_score_broadcasted_friendly(playing_field, this_card, priorities, target_card_type)
    else:
        score += _ai_get_score_broadcasted_enemy(playing_field, this_card, priorities, target_card_type)
    return score


func _ai_get_score_broadcasted_friendly(playing_field, this_card, priorities, target_card_type) -> float:
    # If the target card type is a TURTLE and we don't currently have
    # a TURTLE, then it's worth it to play it in order to keep this
    # card on the field.
    var score = 0.0
    if not (target_card_type is MinionCardType):
        return score
    if not (Archetype.TURTLE in target_card_type.get_base_archetypes()):
        return score

    if not _owner_has_any_turtles(playing_field, this_card.owner):
        var turns_left = get_total_turn_count() - this_card.metadata[CardMeta.TURN_COUNTER]
        score += _ai_get_score_for_extra_turn(playing_field, this_card.owner, priorities) * turns_left

    # Will block the next attack from this TURTLE
    score -= target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func _ai_get_score_broadcasted_enemy(playing_field, this_card, priorities, target_card_type) -> float:
    var score = 0.0
    if not _owner_has_any_turtles_with_good_morale(playing_field, this_card.owner):
        return score
    if not (target_card_type is MinionCardType):
        return score

    # Will block one attack from this Minion
    var turns_left = get_total_turn_count() - this_card.metadata[CardMeta.TURN_COUNTER]
    if turns_left > 0:
        score -= target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func _owner_has_any_turtles_with_good_morale(playing_field, owner) -> bool:
    return (
        Query.on(playing_field)
        .minions(owner)
        .filter(Query.morale().greater_than(1))
        .any(Query.by_archetype(Archetype.TURTLE))
    )
