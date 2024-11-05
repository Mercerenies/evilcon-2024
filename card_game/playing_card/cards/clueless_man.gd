extends EffectCardType


func get_id() -> int:
    return 94


func get_title() -> String:
    return "Clueless Man"


func get_text() -> String:
    return "No effect."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 128


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    # Clueless Man only evaluates hero checks. He has no other effect,
    # so the only thing he's good for is negating Kidnapping the
    # President cards played by your opponent.
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.do_hero_check(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # All Clueless Man does it run a hero check. That's it.
    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
    return score
