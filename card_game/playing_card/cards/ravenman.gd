extends EffectCardType


func get_id() -> int:
    return 87


func get_title() -> String:
    return "Ravenman"


func get_text() -> String:
    return "Exile your opponent's most powerful Minion; then exile Ravenman. Limit 1 per deck."


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 74


func is_hero() -> bool:
    return true


func is_limited() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var was_hero_blocked = await _evaluate_effect(playing_field, card)
    if was_hero_blocked:
        # If this card's effect was fully negated (by a hostage card),
        # do not exile.
        await CardGameApi.destroy_card(playing_field, card)
    else:
        await CardGameApi.exile_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> bool:
    # Returns true if the effect was blocked by a Hero-blocking card.
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return true

    # Destroy most powerful opponent Minion.
    var target_minion = CardEffects.most_powerful_minion(playing_field, CardPlayer.other(owner))
    if target_minion == null:
        # No minions in play
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return false

    var can_influence = await target_minion.card_type.do_influence_check(playing_field, target_minion, card, false)
    if can_influence:
        await CardGameApi.exile_card(playing_field, target_minion)

    return false
