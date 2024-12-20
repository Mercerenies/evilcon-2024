extends EffectCardType


func get_id() -> int:
    return 2


func get_title() -> String:
    return "Pot of Linguine"


func get_text() -> String:
    return "Draw two cards. Limit 1 per deck."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 2


func is_limited() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)
    await CardGameApi.draw_cards(playing_field, owner, 2)
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var cards_in_hand = playing_field.get_hand(player).cards().card_count() - 1  # Subtract Pot of Linguine
    var max_hand_size = StatsCalculator.get_hand_limit(playing_field, player)
    var cards_to_draw = mini(2, max_hand_size - cards_in_hand)
    score += cards_to_draw * priorities.of(LookaheadPriorities.EFFECT_DRAW)

    return score
