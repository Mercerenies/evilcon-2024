extends MinionCardType


func get_id() -> int:
    return 163


func get_title() -> String:
    return "Hyperactive Bee"


func get_text() -> String:
    return "Hyperactive Bee attacks twice per turn."


func get_picture_index() -> int:
    return 176


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.BEE]


func get_rarity() -> int:
    return Rarity.RARE


func on_attack_phase(playing_field, this_card) -> void:
    # Hyperactive Bee performs its owner's Attack Phase twice.
    await super.on_attack_phase(playing_field, this_card)
    if playing_field.turn_player == this_card.owner:
        await super.on_attack_phase(playing_field, this_card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # Add the expected damage (= level * morale) of the card a second
    # time, since Hyperactive Bee attacks twice per turn.
    score += get_base_level() * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_expected_remaining_score(playing_field, card) -> float:
    var score = super.ai_get_expected_remaining_score(playing_field, card)
    if card == null:
        score += get_base_level() * get_base_morale()
    else:
        score += get_level(playing_field, card) * get_morale(playing_field, card)
    return score

# TODO: Can we teach the AI that boosting Hyperactive Bee's Morale is actually really good?
