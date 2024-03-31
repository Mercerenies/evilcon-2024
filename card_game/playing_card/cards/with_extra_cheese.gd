extends TimedCardType


func get_id() -> int:
    return 57


func get_title() -> String:
    return "With Extra Cheese"


func get_text() -> String:
    return "Draw one extra card per turn. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 24


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_cards_per_turn_modifier(_playing_field, card, player: StringName) -> int:
    return 1 if player == card.owner else 0
