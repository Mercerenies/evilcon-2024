extends MinionCardType


func get_id() -> int:
    return 80


func get_title() -> String:
    return "Minionman"


func get_text() -> String:
    return "When Minionman is played, play a random Cost 1 Minion from your deck."


func get_picture_index() -> int:
    return 47


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    var owner = card.owner

    await CardGameApi.highlight_card(playing_field, card)

    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(func (deck_card):
        return deck_card is MinionCardType and deck_card.get_star_cost() <= 1)
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        # Choose a target minion and play
        var target_minion = playing_field.randomness.choose(valid_target_minions)
        await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)
