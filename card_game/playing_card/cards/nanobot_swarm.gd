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

