extends EffectCardType


func get_id() -> int:
    return 60


func get_title() -> String:
    return "Damsel in Distress"


func get_text() -> String:
    return "Next time your opponent plays a Hero card, negate its effect; then destroy this card."


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 97


func get_rarity() -> int:
    return Rarity.COMMON


func do_active_hero_check(playing_field, card, hero_card) -> bool:
    if card.owner != hero_card.owner:
        await CardGameApi.highlight_card(playing_field, card)
        Stats.show_text(playing_field, card, PopupText.BLOCKED)
        await CardGameApi.destroy_card(playing_field, card)
        return false
    return await super.do_active_hero_check(playing_field, card, hero_card)
