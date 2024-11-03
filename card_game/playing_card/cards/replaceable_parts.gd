extends EffectCardType


func get_id() -> int:
    return 135


func get_title() -> String:
    return "Replaceable Parts"


func get_text() -> String:
    return "[font_size=12]Destroy your weakest [icon]ROBOT[/icon] ROBOT Minion; your strongest [icon]ROBOT[/icon] ROBOT Minion gains Level and Morale equal to those of the destroyed Minion.[/font_size]"


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 150


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var robot_minions = (
        playing_field.get_minion_strip(owner).cards()
        .card_array()
        .filter(func (minion): return minion.has_archetype(playing_field, Archetype.ROBOT))
    )
    await CardGameApi.highlight_card(playing_field, this_card)
    if len(robot_minions) <= 1:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    robot_minions.sort_custom(CardEffects.card_power_less_than(playing_field))
    var weakest_minion_level = robot_minions[0].card_type.get_level(playing_field, robot_minions[0])
    var weakest_minion_morale = robot_minions[0].card_type.get_morale(playing_field, robot_minions[0])
    var strongest_minion = robot_minions[-1]
    await CardGameApi.destroy_card(playing_field, robot_minions[0])
    await Stats.add_level(playing_field, strongest_minion, weakest_minion_level, {
        "offset": Stats.CARD_MULTI_UI_OFFSET,
    })
    await Stats.add_morale(playing_field, strongest_minion, weakest_minion_morale)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Find target robots.
    var most_powerful_robot = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.ROBOT))
        .max()
    )
    var weakest_robot = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.ROBOT))
        .min()
    )
    if most_powerful_robot == null or weakest_robot == null or most_powerful_robot == weakest_robot:
        return score  # No target, so the card has no effect.

    var weak_level = weakest_robot.card_type.get_level(playing_field, weakest_robot)
    var weak_morale = weakest_robot.card_type.get_level(playing_field, weakest_robot)
    var strong_level = most_powerful_robot.card_type.get_level(playing_field, most_powerful_robot)
    var strong_morale = most_powerful_robot.card_type.get_level(playing_field, most_powerful_robot)
    var defense_priority = priorities.of(LookaheadPriorities.FORT_DEFENSE)
    # Subtract the damage lost by sacrificing the weaker robot.
    score -= weak_level * weak_morale * defense_priority
    # Add the damage gained by bolstering the stronger robot.
    score += (weak_level * strong_morale + strong_level * weak_morale + weak_level * weak_morale) * defense_priority

    return score
