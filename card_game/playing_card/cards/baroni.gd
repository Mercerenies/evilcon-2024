extends MinionCardType


func get_id() -> int:
    return 174


func get_title() -> String:
    return "B'aroni"


func get_text() -> String:
    return "When B'aroni expires, gain 4 EP and summon a random [icon]ROBOT[/icon] ROBOT Minion of Cost at most 2 from your deck to the field."


func get_picture_index() -> int:
    return 191


func get_star_cost() -> int:
    return 8


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    await CardGameApi.highlight_card(playing_field, this_card)
    await Stats.add_evil_points(playing_field, this_card.owner, 4)
    await _play_random_robot(playing_field, this_card)


func _play_random_robot(playing_field, this_card) -> void:
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_summon_candidate)

    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    # Prefer a Cost 2 Minion if one exists.
    if valid_target_minions.any(func (c): return c.get_star_cost() == 2):
        valid_target_minions = valid_target_minions.filter(func (c): return c.get_star_cost() == 2)

    var target_minion = playing_field.randomness.choose(valid_target_minions)
    await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)


func _is_summon_candidate(deck_card) -> bool:
    return (
        deck_card is MinionCardType and
        Archetype.ROBOT in deck_card.get_base_archetypes() and
        deck_card.get_star_cost() <= 2
    )
