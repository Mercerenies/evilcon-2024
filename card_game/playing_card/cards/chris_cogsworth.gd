extends MinionCardType


func get_id() -> int:
    return 151


func get_title() -> String:
    return "Chris Cogsworth"


func get_text() -> String:
    return "When Chris Cogsworth expires, all of your effects which \"last X turns\" last an extra turn."


func get_picture_index() -> int:
    return 155


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    await CardGameApi.highlight_card(playing_field, this_card)

    var succeeded = false
    for card in playing_field.get_effect_strip(this_card.owner).cards().card_array():
        if await _try_to_apply(playing_field, this_card, card):
            succeeded = true
    if not succeeded:
        # There were no valid targets, so show appropriate UI.
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })


# Returns true if the target was valid (even if the influence check
# failed)
func _try_to_apply(playing_field, this_card, target_card) -> bool:
    if this_card.owner != target_card.owner:
        return false
    if not (CardMeta.TURN_COUNTER in target_card.metadata):
        return false

    var can_influence = await target_card.card_type.do_influence_check(playing_field, target_card, this_card, false)
    if can_influence:
        target_card.metadata[CardMeta.TURN_COUNTER] -= 1
    playing_field.emit_cards_moved()
    return true
