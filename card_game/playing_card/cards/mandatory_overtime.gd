extends TimedCardType


func get_id() -> int:
    return 107


func get_title() -> String:
    return "Mandatory Overtime"


func get_text() -> String:
    return "Your [icon]HUMAN[/icon] HUMAN Minions with 1 Morale do not decrease Morale. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 131


func get_rarity() -> int:
    return Rarity.UNCOMMON


func do_morale_phase_check(playing_field, this_card, performing_card) -> bool:
    if not await super.do_morale_phase_check(playing_field, this_card, performing_card):
        return false
    if this_card.owner != performing_card.owner:
        return true
    if performing_card.card_type is MinionCardType and not performing_card.has_archetype(playing_field, Archetype.HUMAN):
        return true
    if performing_card.metadata[CardMeta.MORALE] != 1:
        return true
    await CardGameApi.highlight_card(playing_field, this_card)
    return false
