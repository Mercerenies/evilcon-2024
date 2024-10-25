extends EffectCardType


func get_id() -> int:
    return 149


func get_title() -> String:
    return "Shell Polishing"


func get_text() -> String:
    return "+1 Morale to all of your [icon]TURTLE[/icon] TURTLE Minions."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 170


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var owner = this_card.owner
    var target_minions = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func (c): return c.has_archetype(playing_field, Archetype.TURTLE))
    )
    if len(target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return
    for minion in target_minions:
        await Stats.add_morale(playing_field, minion, 1)
