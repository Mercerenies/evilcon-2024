extends EffectCardType


func get_id() -> int:
    return 190


func get_title() -> String:
    return "Refrigeration"


func get_text() -> String:
    return "During your next Standby Phase, gain 3 EP; then destroy this card."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 203


func get_rarity() -> int:
    return Rarity.COMMON


func is_ongoing() -> bool:
    return true


func on_standby_phase(playing_field, this_card) -> void:
    await super.on_standby_phase(playing_field, this_card)
    if this_card.owner == playing_field.turn_player:
        await _evaluate_effect(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    await Stats.add_evil_points(playing_field, this_card.owner, 3)
    await CardGameApi.destroy_card(playing_field, this_card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    # We will get the EP back, so Refrigeration is basically a wash.
    score += 3.0 * priorities.of(LookaheadPriorities.EVIL_POINT)

    # Refrigeration is ALWAYS at a slight wrong order penalty, since
    # it's always preferable to play a normal Minion at curve rather
    # than Refrigeration, if possible.
    score -= priorities.of(LookaheadPriorities.MINOR_RIGHT_ORDER)

    return score
