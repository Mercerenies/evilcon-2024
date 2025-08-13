extends MinionCardType


func get_id() -> int:
    return 128


func get_title() -> String:
    return "Barry"


func get_text() -> String:
    return "Each turn, during your End Phase, create a random Cost 2 [icon]ROBOT[/icon] ROBOT Minion."


func get_picture_index() -> int:
    return 48


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_end_phase(playing_field, card) -> void:
    if card.owner == playing_field.turn_player:
        await CardGameApi.highlight_card(playing_field, card)
        var chosen_card_id = playing_field.randomness.choose(PlayingCardLists.BARRYS_ROBOTS)
        var chosen_card_type = PlayingCardCodex.get_entity(chosen_card_id)
        await CardGameApi.create_card(playing_field, card.owner, chosen_card_type)
    await super.on_end_phase(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # Barry will create a Cost 2 Minion during every End Phase of his life.
    score += get_base_morale() * 2 * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_expected_remaining_score(playing_field, card) -> float:
    var score = super.ai_get_expected_remaining_score(playing_field, card)
    var morale = get_base_morale() if card == null else get_morale(playing_field, card)
    score += 2 * maxi(morale - 1, 0)  # -1 because Barry summons during the End Phase, not the Morale Phase.
    return score
