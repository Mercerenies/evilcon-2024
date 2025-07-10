extends EffectCardType


func get_id() -> int:
    return 181


func get_title() -> String:
    return "Life Force Cannon"


func get_text() -> String:
    return "If you control exactly one Minion, then deal 5 damage to your enemy's fortress."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 190


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var minions_count = playing_field.get_minion_strip(owner).cards().card_count()
    if minions_count != 1:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    await Stats.add_fort_defense(playing_field, CardPlayer.other(owner), -5)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var minions_count = playing_field.get_minion_strip(player).cards().card_count()
    if minions_count != 1:
        # No effect
        return score
    score += 5.0 * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
