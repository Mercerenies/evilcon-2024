extends EffectCardType

const Chicken = preload("res://card_game/playing_card/cards/chicken.gd")


func get_id() -> int:
    return 140


func get_title() -> String:
    return "Chick-inator"


func get_text() -> String:
    return "One random enemy Minion is replaced with a Chicken."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 148


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, this_card) -> void:
    var opponent = CardPlayer.other(this_card.owner)

    # Choose a random Minion and destroy it.
    var minions = playing_field.get_minion_strip(opponent).cards().card_array()
    if len(minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return
    var chosen_minion = playing_field.randomness.choose(minions)
    var can_influence = await chosen_minion.card_type.do_influence_check(playing_field, chosen_minion, this_card, false)
    if can_influence:
        await CardGameApi.destroy_card(playing_field, chosen_minion)
        await CardGameApi.create_card(playing_field, opponent, Chicken.new())
