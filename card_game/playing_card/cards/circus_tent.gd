extends TimedCardType


func get_id() -> int:
    return 170


func get_title() -> String:
    return "Circus Tent"


func get_text() -> String:
    return "Minions of Cost 2 or less played by your opponent are now of type [icon]CLOWN[/icon] CLOWN. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 66


func get_rarity() -> int:
    return Rarity.COMMON


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if this_card.owner == played_card.owner:
        return
    if played_card.card_type.get_star_cost() > 2:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, played_card, PopupText.CLOWNED)
        played_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()
