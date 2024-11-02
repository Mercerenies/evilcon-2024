extends MinionCardType


func get_id() -> int:
    return 126


func get_title() -> String:
    return "Milkman Marauder"


func get_text() -> String:
    return "When Milkman Marauder expires, all friendly Minions gain 1 Morale."


func get_picture_index() -> int:
    return 52


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


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var owner = this_card.owner

    await CardGameApi.highlight_card(playing_field, this_card)

    # Do not apply this effect to `self` (we don't want to resurrect `self`.
    var minion_strip = playing_field.get_minion_strip(owner)
    var minions = minion_strip.cards().card_array().filter(func(m): return m != this_card)

    if len(minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        for minion in minions:
            await Stats.add_morale(playing_field, minion, 1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # As of Nov 2, 2024, the average Level of a Minion is 1.7. Assume
    # you will control 2 Minions when Milkman Marauder expires, for a
    # total of a 3.4 damage boost to the enemy's fort.
    score += 3.4 * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType):
        return score

    # If we control Milkman Marauder, then prioritize playing Minions
    # that will outlast him and therefore benefit from his effect.
    if target_card_type.get_base_morale() >= get_morale(playing_field, this_card):
        score += target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
