extends TimedCardType


func get_id() -> int:
    return 55


func get_title() -> String:
    return "Nuclear Fusion Plant"


func get_text() -> String:
    return "+1 EP per turn. Lasts 6 turns."


func get_total_turn_count() -> int:
    return 6


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 12


func get_rarity() -> int:
    return Rarity.RARE


func get_ep_per_turn_modifier(_playing_field, card, player: StringName) -> int:
    return 1 if player == card.owner else 0
