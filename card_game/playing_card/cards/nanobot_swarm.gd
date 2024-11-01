extends MinionCardType

func get_id() -> int:
    return 77


func get_title() -> String:
    return "Nanobot Swarm"


func get_text() -> String:
    return "When Nanobot Swarm expires, your most powerful [icon]ROBOT[/icon] ROBOT Minion gets +1 Morale."


func get_picture_index() -> int:
    return 61


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.COMMON


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var owner = this_card.owner

    # Find owner's most powerful Robot (other than this card)
    var most_powerful_robot = (
        Query.on(playing_field).minions(owner)
        .filter([Query.by_archetype(Archetype.ROBOT), Query.not_equals(this_card)])
        .max()
    )
    await CardGameApi.highlight_card(playing_field, this_card)
    if most_powerful_robot == null:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET, {
            "offset": 1,
        })
    else:
        var can_influence = await most_powerful_robot.card_type.do_influence_check(playing_field, most_powerful_robot, this_card, false)
        if can_influence:
            await Stats.add_morale(playing_field, most_powerful_robot, 1)


@warning_ignore("CONFUSABLE_LOCAL_DECLARATION")
func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Find the presumptive target.
    var most_powerful_robot = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.ROBOT))
        .filter(func (playing_field, card): return card.card_type.get_morale(playing_field, card) > 1)
        .max()
    )
    if most_powerful_robot != null:
        score += most_powerful_robot.card_type.get_level(playing_field, most_powerful_robot) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # If we control Nanobot Swarm and no other ROBOT Minions,
    # prioritize robots.
    var robot_count = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.ROBOT))
        .count()
    )
    if robot_count < 2 and target_card_type is MinionCardType and Archetype.ROBOT in target_card_type.get_base_archetypes():
        # Nanobot Swarm will expire and give +1 Morale to that Minion
        # if played.
        score += target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
