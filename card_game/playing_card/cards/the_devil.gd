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
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
    else:
        for minion in minion_strip.cards().card_array():
            if minion == this_card:
                continue
            var card_node = CardGameApi.find_card_node(playing_field, minion)
            Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
                "custom_label_text": Stats.DEMONED_TEXT,
                "custom_label_color": Stats.DEMONED_COLOR,
            })
            minion.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.DEMON]
    playing_field.emit_cards_moved()
