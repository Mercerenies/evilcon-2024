extends MinionCardType


func get_id() -> int:
    return 165


func get_title() -> String:
    return "Ice Moth"


func get_text() -> String:
    return "When Ice Moth is played, your opponent's most powerful Minion loses 1 Morale."


func get_picture_index() -> int:
    return 177


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NATURE]


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, this_card) -> void:
    await super.on_play(playing_field, this_card)
    await _try_to_perform_effect(playing_field, this_card)


func _try_to_perform_effect(playing_field, this_card) -> void:
    var opponent = CardPlayer.other(this_card.owner)
    var target_minion = CardEffects.most_powerful_minion(playing_field, opponent)
    if target_minion == null:
        # No minions in play
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var can_influence = await target_minion.card_type.do_influence_check(playing_field, target_minion, this_card, false)
    if not can_influence:
        # Effect was blocked
        return

    await Stats.add_morale(playing_field, target_minion, -1)
