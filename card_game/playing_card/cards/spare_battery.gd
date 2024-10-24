extends EffectCardType


func get_id() -> int:
    return 52


func get_title() -> String:
    return "Spare Battery"


func get_text() -> String:
    return "Your most powerful [icon]ROBOT[/icon] ROBOT Minion gets +1 Level and +1 Morale."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 22


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var owner = card.owner

    # Find owner's most powerful Robot.
    var minions = (
        playing_field.get_minion_strip(owner).cards()
        .card_array()
        .filter(func (minion): return minion.has_archetype(playing_field, Archetype.ROBOT))
    )
    await CardGameApi.highlight_card(playing_field, card)
    if len(minions) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        var most_powerful_robot = Util.max_by(minions, CardEffects.card_power_less_than(playing_field))
        var can_influence = await most_powerful_robot.card_type.do_influence_check(playing_field, most_powerful_robot, card, false)
        if can_influence:
            await Stats.add_level(playing_field, most_powerful_robot, 1, {
                "offset": Stats.CARD_MULTI_UI_OFFSET,
            })
            await Stats.add_morale(playing_field, most_powerful_robot, 1)
    await CardGameApi.destroy_card(playing_field, card)
