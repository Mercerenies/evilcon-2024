extends EffectCardType

const Chicken = preload("res://card_game/playing_card/cards/chicken.gd")


func get_id() -> int:
    return 184


func get_title() -> String:
    return "Poultry Farm"


func get_text() -> String:
    return "During your Standby Phase, summon a Chicken from your deck to the field. If you have no such cards in your deck, destroy this card."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 184


func get_rarity() -> int:
    return Rarity.UNCOMMON


func is_ongoing() -> bool:
    return true


func on_standby_phase(playing_field, this_card) -> void:
    await super.on_standby_phase(playing_field, this_card)
    if this_card.owner == playing_field.turn_player:
        await _evaluate_effect(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_chicken_card_type)
    if len(valid_target_minions) == 0:
        await CardGameApi.destroy_card(playing_field, this_card)
    else:
        # Choose a target minion and play
        var target_minion = valid_target_minions[-1]
        var new_card = await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)
        new_card.metadata[CardMeta.SKIP_MORALE] = true


func _is_chicken_card_type(card_type) -> bool:
    return card_type.get_id() == Chicken.new().get_id()
