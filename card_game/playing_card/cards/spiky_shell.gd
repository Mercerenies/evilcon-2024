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
