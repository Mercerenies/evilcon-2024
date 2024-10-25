extends MinionCardType


func get_id() -> int:
    return 129


func get_title() -> String:
    return "The Devil"


func get_text() -> String:
    return "When The Devil expires, convert all friendly Minions to [icon]DEMON[/icon] DEMON Minions."


func get_picture_index() -> int:
    return 121


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var owner = this_card.owner
    var minion_strip = playing_field.get_minion_strip(owner)
    await CardGameApi.highlight_card(playing_field, this_card)

    if minion_strip.cards().card_count() <= 1:  # <= 1 because this card is still in play.
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        for minion in minion_strip.cards().card_array():
            if minion == this_card:
                continue
            Stats.show_text(playing_field, minion, PopupText.DEMONED)
            minion.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.DEMON]
    playing_field.emit_cards_moved()
