extends EffectCardType


func get_id() -> int:
    return 53


func get_title() -> String:
    return "Milk Delivery"


func get_text() -> String:
    return "+1 Morale to all of your Minions."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 23


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var owner = card.owner
    var minion_strip = playing_field.get_minion_strip(owner)
    await CardGameApi.highlight_card(playing_field, card)

    if len(minions) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
    else:
        for minion in minion_strip.cards().card_array():
            await Stats.add_morale(playing_field, minion, 1)
    await CardGameApi.destroy_card(playing_field, card)
