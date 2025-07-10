extends EffectCardType


func get_id() -> int:
    return 99


func get_title() -> String:
    return "Vitamin Capsule"


func get_text() -> String:
    return "Leave this card in play. If you have three Vitamin Capsules, destroy all three and deal 10 damage to your opponent's fortress."


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 83


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    var owner = card.owner
    var opponent = CardPlayer.other(owner)
    super.on_play(playing_field, card)

    var vitamins_in_play = _get_all_vitamin_capsules(playing_field, owner)
    if len(vitamins_in_play) >= 3:
        await CardGameApi.highlight_card(playing_field, card)
        await _play_vitamin_animation(playing_field, vitamins_in_play)
        await Stats.add_fort_defense(playing_field, opponent, -10)
        for vitamin in vitamins_in_play:
            await CardGameApi.destroy_card(playing_field, vitamin)


func _get_all_vitamin_capsules(playing_field, owner) -> Array:
    var all_effects = playing_field.get_effect_strip(owner).cards().card_array()
    return all_effects.filter(func (c):
        return c.card_type.get_id() == self.get_id())


func _play_animation_for_vitamin(playing_field, vitamin_card, promise) -> void:
    await CardGameApi.rotate_card(playing_field, vitamin_card)
    promise.resolve()


func _play_vitamin_animation(playing_field, vitamins_in_play: Array) -> void:
    var promises = vitamins_in_play.map(func (vitamin):
        var promise = Promise.new()
        _play_animation_for_vitamin(playing_field, vitamin, promise)
        return promise)
    await Promise.async_all(promises)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Easiest valuation in the world. A Vitamin Capsule is worth 1/3
    # of its total resolution, so 10/3.
    score += (10.0 / 3.0) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
