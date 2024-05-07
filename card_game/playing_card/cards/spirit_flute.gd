extends EffectCardType


func get_id() -> int:
    return 105


func get_title() -> String:
    return "Spirit Flute"


func get_text() -> String:
    return "All of your [icon]UNDEAD[/icon] UNDEAD Minions immediately attack and then drop Morale."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 91


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, card) -> void:
    var owner = card.owner
    var undead_minions = (
        playing_field.get_minion_strip(owner).cards()
        .card_array()
        .filter(func (c): return c.has_archetype(playing_field, Archetype.UNDEAD))
    )
    if len(undead_minions) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return
    for minion in undead_minions:
        await minion.card_type.on_attack_phase(playing_field, minion)
    for minion in undead_minions:
        await minion.card_type.on_morale_phase(playing_field, minion)
