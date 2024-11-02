extends MinionCardType


func get_id() -> int:
    return 98


func get_title() -> String:
    return "Count Carbonara"


func get_text() -> String:
    return "+1 hand limit while Count Carbonara is in play."


func get_picture_index() -> int:
    return 196


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func get_hand_limit_modifier(_playing_field, card, player: StringName) -> int:
    return 1 if player == card.owner else 0


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    score += get_base_morale() * priorities.of(LookaheadPriorities.HAND_LIMIT_UP)
    return score
