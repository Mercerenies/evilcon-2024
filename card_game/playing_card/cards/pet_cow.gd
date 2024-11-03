extends EffectCardType


func get_id() -> int:
    return 106


func get_title() -> String:
    return "Pet Cow"


func get_text() -> String:
    return "+2 Morale to your most powerful Minion."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 130


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, card) -> void:
    var owner = card.owner
    var target_minion = CardEffects.most_powerful_minion(playing_field, owner)
    if target_minion == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        await Stats.add_morale(playing_field, target_minion, 2)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var target_minion = CardEffects.most_powerful_minion(playing_field, player)
    if target_minion != null:
        score += 2 * target_minion.card_type.get_level(playing_field, target_minion) * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
