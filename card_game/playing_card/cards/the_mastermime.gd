extends MinionCardType


func get_id() -> int:
    return 115


func get_title() -> String:
    return "The Mastermime"


func get_text() -> String:
    return "All new Minions played by your opponent are now of type [icon]CLOWN[/icon] CLOWN."


func get_picture_index() -> int:
    return 109


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if this_card.owner == played_card.owner:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = await played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        var card_node = CardGameApi.find_card_node(playing_field, played_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.CLOWNED_TEXT,
            "custom_label_color": Stats.CLOWNED_COLOR,
        })
        played_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()
