extends TimedCardType


func get_id() -> int:
    return 58


func get_title() -> String:
    return "Cover of Moonlight"


func get_text() -> String:
    return "Your Minions are immune to enemy card effects. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 16


func get_rarity() -> int:
    return Rarity.RARE


func do_broadcasted_influence_check(playing_field, card, target_card, source_card, silently: bool) -> bool:
    if card.owner == target_card.owner and card.owner != source_card.owner:
        if not silently:
            var card_node = CardGameApi.find_card_node(playing_field, target_card)
            Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
                "custom_label_text": Stats.BLOCKED_TEXT,
                "custom_label_color": Stats.BLOCKED_COLOR,
            })
        return false
    return await super.do_broadcasted_influence_check(playing_field, card, target_card, source_card, silently)
