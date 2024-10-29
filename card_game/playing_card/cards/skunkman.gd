extends MinionCardType


func get_id() -> int:
    return 186


func get_title() -> String:
    return "Skunkman"


func get_text() -> String:
    return "When Skunkman is played, your opponent discards all Hero cards currently in their hand."


func get_picture_index() -> int:
    return 197


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.NATURE, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var opponent = CardPlayer.other(card.owner)

    await CardGameApi.highlight_card(playing_field, card)
    var cards_to_discard = (
        playing_field.get_hand(opponent).cards().card_array()
        .filter(func(c): return c is EffectCardType and c.is_hero())
    )
    if len(cards_to_discard) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return
    for target_card in cards_to_discard:
        await CardGameApi.discard_card(playing_field, opponent, target_card)
