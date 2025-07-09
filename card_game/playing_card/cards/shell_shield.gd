extends TimedCardType


func get_id() -> int:
    return 168


func get_title() -> String:
    return "Shell Shield"


func get_text() -> String:
    return "If you control at least one [icon]TURTLE[/icon] TURTLE Minion, then enemy Level 1 Minions deal no damage. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 168


func get_rarity() -> int:
    return Rarity.COMMON


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if not _owner_has_any_turtles(playing_field, this_card.owner):
        # Owner has no Turtles, so do nothing.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player as
        # the Shell Shield
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.card_type.get_level(playing_field, attacking_card) > 1:
        # Level is too high, do not block.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    await CardGameApi.highlight_card(playing_field, this_card)

    var can_influence = attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
    if can_influence:  # TODO Consider if we can show this in the UI better, it's confusing right now
        Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
            "offset": 1,
        })
        return -99999

    return super.augment_attack_damage(playing_field, this_card, attacking_card)


func _owner_has_any_turtles(playing_field, owner) -> bool:
    return (
        Query.on(playing_field)
        .minions(owner)
        .any(Query.by_archetype(Archetype.TURTLE))
    )


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    # If we're playing with Shell Shield in our deck, it is reasonable
    # to assume we have enough TURTLE Minions to keep the effect
    # active. So as long as we have one out right now, assume the
    # effect is active.
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)
    if not _owner_has_any_turtles(playing_field, player):
        # No turtles, no effect
        return score

    score += _ai_get_score_for_extra_turn(playing_field, player, priorities)
    return score

func _ai_get_score_for_extra_turn(playing_field, player: StringName, priorities) -> float:
    var score = 0.0

    # We have turtles, so count the number of influence-able Level 1
    # Minions that will be blocked by this effect.
    for minion in Query.on(playing_field).minions(CardPlayer.other(player)).array():
        var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, minion, self, player)
        var level = minion.card_type.get_level(playing_field, minion)
        if can_influence and level <= 1:
            # Exciting corner case: Technically "<= 1" even though the
            # card text says "== 1". Doubt this ever matters but it is
            # technically correct.
            score += level * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


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
    if _owner_has_any_turtles(playing_field, this_card.owner):
        return score  # Already have a turtle, so no need to play another.

    var turns_left = get_total_turn_count() - this_card.metadata[CardMeta.TURN_COUNTER]
    score += _ai_get_score_for_extra_turn(playing_field, this_card.owner, priorities) * turns_left

    return score


func _ai_get_score_broadcasted_enemy(playing_field, this_card, priorities, target_card_type) -> float:
    var score = 0.0
    if not _owner_has_any_turtles_with_good_morale(playing_field, this_card.owner):
        return score
    if not (target_card_type is MinionCardType):
        return score
    if target_card_type.get_base_level() > 1:
        return score  # Unaffected by Shell Shield
    # If the enemy has Shell Shield and at least one TURTLE that will
    # last a turn, then our Level 1 Minions are not worth as much.
    var turns_left = get_total_turn_count() - this_card.metadata[CardMeta.TURN_COUNTER] - 1
    var turns_blocked = min(target_card_type.get_base_morale(), turns_left)
    score -= turns_blocked * target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func _owner_has_any_turtles_with_good_morale(playing_field, owner) -> bool:
    return (
        Query.on(playing_field)
        .minions(owner)
        .filter(Query.morale().greater_than(1))
        .any(Query.by_archetype(Archetype.TURTLE))
    )
