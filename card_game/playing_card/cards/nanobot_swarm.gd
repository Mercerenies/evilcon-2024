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


func on_expire(playing_field, card) -> void:
    await super.on_expire(playing_field, card)
    var owner = card.owner

    # Find owner's most powerful Robot (other than this card)
    var minions = (
        playing_field.get_minion_strip(owner).cards()
        .card_array()
        .filter(func (minion): return minion != card and minion.has_archetype(playing_field, Archetype.ROBOT))
    )
    await CardGameApi.highlight_card(playing_field, card)
    if len(minions) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
    else:
        var most_powerful_robot = Util.max_by(minions, CardEffects.card_power_less_than(playing_field))
        var can_influence = await most_powerful_robot.card_type.do_influence_check(playing_field, most_powerful_robot, card, false)
        if can_influence:
            await Stats.add_morale(playing_field, most_powerful_robot, 1)
