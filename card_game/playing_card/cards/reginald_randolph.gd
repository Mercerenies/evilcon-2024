extends MinionCardType


func get_id() -> int:
    return 209


func get_title() -> String:
    return "Reginald Randolph"


func get_text() -> String:
    return "Each turn, during your End Phase, play a random Cost 1 Minion from your deck."


func get_picture_index() -> int:
    return 224


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_end_phase(playing_field, card) -> void:
    await super.on_end_phase(playing_field, card)

    var owner = card.owner
    if owner != playing_field.turn_player:
        return

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


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # Reginald will summon a Cost 1 Minion during every End Phase of
    # his life, assuming such a card exists in the deck.
    var deck = playing_field.get_deck(player)
    var valid_target_minions = deck.cards().card_array().filter(func (deck_card):
        return deck_card is MinionCardType and deck_card.get_star_cost() <= 1)
    score += mini(len(valid_target_minions), get_base_morale()) * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_expected_remaining_score(playing_field, card) -> float:
    var score = super.ai_get_expected_remaining_score(playing_field, card)
    var morale = get_base_morale() if card == null else get_morale(playing_field, card)
    score += maxi(morale - 1, 0)  # -1 because Reginald summons during the End Phase, not the Morale Phase.
    return score
