extends TimedCardType


func get_id() -> int:
    return 137


func get_title() -> String:
    return "Library of Alexandria"


func get_text() -> String:
    return "[icon]HUMAN[/icon] HUMAN Minions do not drop morale, regardless of owner. Lasts 1 turn."


func get_total_turn_count() -> int:
    return 1


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 151


func get_rarity() -> int:
    return Rarity.RARE


func do_morale_phase_check(playing_field, this_card, performing_card) -> bool:
    if not await super.do_morale_phase_check(playing_field, this_card, performing_card):
        return false
    if performing_card.card_type is MinionCardType and performing_card.has_archetype(playing_field, Archetype.HUMAN):
        await CardGameApi.highlight_card(playing_field, this_card)
        return false
    return true
