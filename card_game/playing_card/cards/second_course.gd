extends TimedCardType


func get_id() -> int:
    return 56


func get_title() -> String:
    return "Second Course"


func get_text() -> String:
    return "+1 hand limit. Lasts 4 turns."


func get_total_turn_count() -> int:
    return 4


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 84


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_hand_limit_modifier(_playing_field, card, player: StringName) -> int:
    return 1 if player == card.owner else 0
