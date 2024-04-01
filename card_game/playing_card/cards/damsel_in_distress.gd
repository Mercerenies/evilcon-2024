extends TimedCardType


func get_id() -> int:
    return 61


func get_title() -> String:
    return "Damsel in Distress"


func get_text() -> String:
    return "Hero cards played by your opponent have no effect. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 97


func get_rarity() -> int:
    return Rarity.COMMON


func do_passive_hero_check(playing_field, card, hero_card) -> bool:
    if card.owner != hero_card.owner:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.BLOCKED_TEXT,
            "custom_label_color": Stats.BLOCKED_COLOR,
        })
        return false
    return super.do_passive_hero_check(playing_field, card, hero_card)
