extends EffectCardType


func get_id() -> int:
    return 2


func get_title() -> String:
    return "Pot of Linguine"


func get_text() -> String:
    return "Draw two cards; limit 1 per deck"


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 2


func is_limited() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.UNCOMMON
