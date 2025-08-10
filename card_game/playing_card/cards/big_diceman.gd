extends MinionCardType


func get_id() -> int:
    return 207


func get_title() -> String:
    return "Big Diceman"


func get_text() -> String:
    return "When you discard N cards at once for any reason, deal N² damage to the enemy's fort."


func get_picture_index() -> int:
    return 213


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_cards_discarded(playing_field, this_card, discarding_player: StringName, cards_discarded) -> void:
    if this_card.owner == discarding_player:
        await CardGameApi.highlight_card(playing_field, this_card)
        var damage = len(cards_discarded) * len(cards_discarded)
        if damage >= 0:
            await Stats.add_fort_defense(playing_field, CardPlayer.other(discarding_player), - damage)


func ai_get_value_of_discarding(playing_field, this_card, activating_player: StringName, discarding_player: StringName, cards_to_discard, priorities) -> float:
    var score = super.ai_get_value_of_discarding(playing_field, this_card, activating_player, discarding_player, cards_to_discard, priorities)
    if discarding_player != this_card.owner:
        return score

    var sign_of_score = 1.0 if this_card.owner == activating_player else - 1.0
    score += sign_of_score * float(cards_to_discard) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score

# TODO Wrong order penalty for playing a discarding card before
# playing Big Diceman? How do we detect this?
