extends EffectCardType


func get_id() -> int:
    return 198


func get_title() -> String:
    return "Blue Dice"


func get_text() -> String:
    return "No effect."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 212


func is_dice() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    # No effect if played on its own.
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.do_hero_check(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    score -= priorities.of(LookaheadPriorities.THROWING_DICE)
    return score
