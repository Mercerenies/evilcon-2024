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
            Stats.show_text(playing_field, target_card, PopupText.BLOCKED)
        return false
    return super.do_broadcasted_influence_check(playing_field, card, target_card, source_card, silently)
