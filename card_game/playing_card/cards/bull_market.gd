extends TimedCardType


func get_id() -> int:
    return 162


func get_title() -> String:
    return "Bull Market"


func get_text() -> String:
    return "All [icon]HUMAN[/icon] HUMAN Minions played while this card is in play start with +1 Morale. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 158


func get_rarity() -> int:
    return Rarity.RARE


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if not played_card.has_archetype(playing_field, Archetype.HUMAN):
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = await played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        await Stats.add_morale(playing_field, played_card, 1)
