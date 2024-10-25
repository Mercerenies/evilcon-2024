extends EffectCardType


func get_id() -> int:
    return 136


func get_title() -> String:
    return "Pet Cown"


func get_text() -> String:
    return "+1 Morale to your most powerful Minion for each [icon]CLOWN[/icon] CLOWN Minion your opponent controls, up to a maximum of 3."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 149


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, card) -> void:
    var owner = card.owner
    var opponent = CardPlayer.other(owner)
    var target_minion = CardEffects.most_powerful_minion(playing_field, owner)
    if target_minion == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    var opponent_clowns_count = len(
        playing_field.get_minion_strip(opponent)
        .cards().card_array()
        .filter(func (c): return c.has_archetype(playing_field, Archetype.CLOWN))
    )
    await Stats.add_morale(playing_field, target_minion, min(opponent_clowns_count, 3))
