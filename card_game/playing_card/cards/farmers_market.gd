extends TimedCardType


func get_id() -> int:
    return 185


func get_title() -> String:
    return "Poultry Farm"


func get_text() -> String:
    return "During your Standby Phase, summon a random [icon]FARM[/icon] FARM Minion of Cost at most 2 from your deck."


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 183


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_total_turn_count() -> int:
    return 3


func on_standby_phase(playing_field, this_card) -> void:
    if this_card.owner == playing_field.turn_player:
        await _evaluate_effect(playing_field, this_card)
    await super.on_standby_phase(playing_field, this_card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_valid_target_card_type)
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    # Prefer a Cost 2 Minion if one exists.
    if valid_target_minions.any(func (c): return c.get_star_cost() == 2):
        valid_target_minions = valid_target_minions.filter(func (c): return c.get_star_cost() == 2)

    var target_minion = playing_field.randomness.choose(valid_target_minions)
    await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)


func _is_valid_target_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes and card_type.get_star_cost() <= 2
