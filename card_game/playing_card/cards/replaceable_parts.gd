extends EffectCardType


func get_id() -> int:
    return 135


func get_title() -> String:
    return "Replaceable Parts"


func get_text() -> String:
    return "[font_size=12]Destroy your weakest [icon]ROBOT[/icon] ROBOT Minion; your most powerful [icon]ROBOT[/icon] ROBOT Minion gains Level equal to the Level of the destroyed Minion.[/font_size]"


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 150


func get_rarity() -> int:
    return Rarity.UNCOMMON


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
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return

    robot_minions.sort_custom(CardEffects.card_power_less_than(playing_field))
    var weakest_minion_level = robot_minions[0].card_type.get_level(playing_field, robot_minions[0])
    var strongest_minion = robot_minions[-1]
    await CardGameApi.destroy_card(playing_field, robot_minions[0])
    await Stats.add_level(playing_field, strongest_minion, weakest_minion_level)
