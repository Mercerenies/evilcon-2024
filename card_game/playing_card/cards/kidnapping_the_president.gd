extends EffectCardType


func get_id() -> int:
    return 60


func get_title() -> String:
    return "Kidnapping the President"


func get_text() -> String:
    return "Next time your opponent plays a Hero card, negate its effect; then destroy this card."


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 98


func get_rarity() -> int:
    return Rarity.UNCOMMON


func do_active_hero_check(playing_field, card, hero_card) -> bool:
    if card.owner != hero_card.owner:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        await CardGameApi.highlight_card(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.BLOCKED_TEXT,
            "custom_label_color": Stats.BLOCKED_COLOR,
        })
        await CardGameApi.destroy_card(playing_field, card)
        return false
    return super.do_active_hero_check(playing_field, card, hero_card)
