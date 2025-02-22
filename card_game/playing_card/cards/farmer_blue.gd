extends MinionCardType


func get_id() -> int:
    return 82


func get_title() -> String:
    return "Farmer Blue"


func get_text() -> String:
    return "Instead of attacking, Farmer Blue summons the top [icon]FARM[/icon] FARM Minion from your deck to the field."


func get_picture_index() -> int:
    return 42


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_attack_phase(playing_field, card) -> void:
    # Overrides and does NOT call super. Farmer Blue does not
    # perform a regular attack, even if he has a nonzero Level.
    var owner = card.owner

    if playing_field.turn_player != owner:
        return

    await CardGameApi.highlight_card(playing_field, card)

    # Check if anything blocks the Attack Phase.
    var should_proceed = await CardEffects.do_attack_phase_check(playing_field, card)
    if not should_proceed:
        return

    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_farm_card_type)
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        # Choose a target minion and play
        var target_minion = valid_target_minions[-1]
        var new_card = await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)
        new_card.metadata[CardMeta.SKIP_MORALE] = true


func _is_farm_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # As of Nov 2, 2024, the average EP cost of a playing card is 3.2.
    # Assume that we will find a valid FARM Minion of this cost in the
    # deck and will play it at curve.
    score += get_base_morale() * 3.2 * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_expected_remaining_score(playing_field, card) -> float:
    var score = super.ai_get_expected_remaining_score(playing_field, card)
    var remaining_morale = get_base_morale() if card == null else get_morale(playing_field, card)
    # As of Nov 2, 2024, the average EP cost of a playing card is 3.2.
    # Assume that we will find a valid FARM Minion of this cost in the
    # deck and will play it at curve.
    score += remaining_morale * 3.2
    return score
