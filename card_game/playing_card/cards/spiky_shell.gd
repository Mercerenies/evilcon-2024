extends TimedCardType


func get_id() -> int:
    return 148


func get_title() -> String:
    return "Spiky Shell"


func get_text() -> String:
    return "All [icon]TURTLE[/icon] TURTLE Minions you control count as \"Spiky\". Lasts 4 turns."


func get_total_turn_count() -> int:
    return 4


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 169


func get_rarity() -> int:
    return Rarity.COMMON


func is_spiky_broadcasted(playing_field, this_card, candidate_card) -> bool:
    if candidate_card.owner == this_card.owner and candidate_card.card_type is MinionCardType and candidate_card.has_archetype(playing_field, Archetype.TURTLE):
        return true
    return super.is_spiky_broadcasted(playing_field, this_card, candidate_card)


func ai_will_be_spiky_broadcasted(playing_field, this_card, candidate_card_type, candidate_owner):
    if candidate_owner == this_card.owner and candidate_card_type is MinionCardType and Archetype.TURTLE in candidate_card_type.get_base_archetypes():
        return true
    return super.ai_will_be_spiky_broadcasted(playing_field, this_card, candidate_card_type, candidate_owner)


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    for minion in playing_field.get_minion_strip(player).cards().card_array():
        if minion.has_archetype(playing_field, Archetype.TURTLE):
            score += priorities.of(LookaheadPriorities.SPIKY)

    return score
