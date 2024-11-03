extends TimedCardType


func get_id() -> int:
    return 54


func get_title() -> String:
    return "Nuclear Power Plant"


func get_text() -> String:
    return "+1 EP per turn. Lasts 4 turns."


func get_total_turn_count() -> int:
    return 4


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 11


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_ep_per_turn_modifier(_playing_field, card, player: StringName) -> int:
    return 1 if player == card.owner else 0


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    return (
        super.ai_get_score_per_turn(playing_field, player, priorities) +
        priorities.of(LookaheadPriorities.EVIL_POINT)
    )
