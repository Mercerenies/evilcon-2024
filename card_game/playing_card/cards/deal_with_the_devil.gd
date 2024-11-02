extends EffectCardType


func get_id() -> int:
    return 179


func get_title() -> String:
    return "Deal with the Devil"


func get_text() -> String:
    return "Gain 4 EP immediately when you play this card. During your End Phase, if you control more than one Minion, destroy this card and all Minions you control."


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 175


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, this_card) -> void:
    await super.on_play(playing_field, this_card)
    await CardGameApi.highlight_card(playing_field, this_card)
    await Stats.add_evil_points(playing_field, this_card.owner, 4)


func on_end_phase(playing_field, this_card) -> void:
    await super.on_end_phase(playing_field, this_card)
    if this_card.owner == playing_field.turn_player:
        await _do_minion_check(playing_field, this_card)


func _do_minion_check(playing_field, this_card) -> void:
    var minions = playing_field.get_minion_strip(this_card.owner).cards()
    if minions.card_count() > 1:
        await CardGameApi.highlight_card(playing_field, this_card)
        for minion in minions.card_array():
            var can_influence = minion.card_type.do_influence_check(playing_field, minion, this_card, false)
            if can_influence:
                await CardGameApi.destroy_card(playing_field, minion)
        await CardGameApi.destroy_card(playing_field, this_card)
