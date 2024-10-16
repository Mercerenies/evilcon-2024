extends TimedCardType


func get_id() -> int:
    return 142


func get_title() -> String:
    return "No-Honk Zone"


func get_text() -> String:
    return "Enemy [icon]CLOWN[/icon] CLOWN Minions deal no damage to your fort. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 153


func get_rarity() -> int:
    return Rarity.UNCOMMON


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player who owns this card.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)

    if attacking_card.has_archetype(playing_field, Archetype.CLOWN):
        await CardGameApi.highlight_card(playing_field, this_card)
        var card_node = CardGameApi.find_card_node(playing_field, attacking_card)
        var can_influence = await attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
        if can_influence:  # TODO Consider if we can show this in the UI better, it's confusing right now
            Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
                "custom_label_text": Stats.BLOCKED_TEXT,
                "custom_label_color": Stats.BLOCKED_COLOR,
                "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
            })
            return -99999
    return super.augment_attack_damage(playing_field, this_card, attacking_card)
