extends EffectCardType

const BabyClown = preload("res://card_game/playing_card/cards/baby_clown.gd")


func get_id() -> int:
    return 139


func get_title() -> String:
    return "Pacifier"


func get_text() -> String:
    return "All enemy [icon]CLOWN[/icon] CLOWN Minions are replaced with Baby Clown Minions."


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
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return

    for minion in minions:
        await CardGameApi.destroy_card(playing_field, minion)

    for _i in range(len(minions)):
        await CardGameApi.create_card(playing_field, opponent, BabyClown.new())
