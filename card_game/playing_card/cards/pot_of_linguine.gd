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
