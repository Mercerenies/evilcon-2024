extends EffectCardType


func get_id() -> int:
    return 108


func get_title() -> String:
    return "Destiny's Singer"


func get_text() -> String:
    return "If you successfully activate this card three times, you win the game immediately. Limit 1 per deck."


func get_star_cost() -> int:
    return 8


func get_picture_index() -> int:
    return 200


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.RARE


func is_limited() -> bool:
    return true


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)

    if await CardEffects.do_hero_check(playing_field, card):
        var node = CardGameApi.find_card_node(playing_field, card)
        await CardGameApi.play_musical_note_animation(playing_field, node)
        await Stats.add_destiny_song(playing_field, card.owner, 1)

    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var hero_check = CardEffects.do_hypothetical_hero_check(playing_field, self, player)
    if hero_check == CardEffects.HeroCheckResult.PASSIVE_FAIL:
        return score
    elif hero_check == CardEffects.HeroCheckResult.ACTIVE_FAIL:
        score += priorities.of(LookaheadPriorities.ELIMINATE_HERO_CHECK)
        return score

    score += priorities.of(LookaheadPriorities.DESTINYS_SONG)
    return score
