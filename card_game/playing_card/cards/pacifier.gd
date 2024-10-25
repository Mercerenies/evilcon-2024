extends EffectCardType

const BabyClown = preload("res://card_game/playing_card/cards/baby_clown.gd")


func get_id() -> int:
    return 139


func get_title() -> String:
    return "Pacifier"


func get_text() -> String:
    return "All enemy [icon]CLOWN[/icon] CLOWN Minions are replaced with Baby Clowns."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 154


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var opponent = CardPlayer.other(this_card.owner)

    # Destroy all opponent Clowns.
    var minions = (
        playing_field.get_minion_strip(opponent).cards()
        .card_array()
        .filter(func (minion): return minion.has_archetype(playing_field, Archetype.CLOWN))
    )
    if len(minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var successful_destructions = 0
    for minion in minions:
        var can_influence = await minion.card_type.do_influence_check(playing_field, minion, this_card, false)
        if can_influence:
            await CardGameApi.destroy_card(playing_field, minion)
            successful_destructions += 1

    for _i in successful_destructions:
        await CardGameApi.create_card(playing_field, opponent, BabyClown.new())
