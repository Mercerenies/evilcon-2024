extends MinionCardType


# TODO What happens if we make Death be UNDEAD-DEMON-BOSS Synergy? It
# feels too powerful to let him be UNDEAD, so I'm leaning towards no.

func get_id() -> int:
    return 116


func get_title() -> String:
    return "Death"


func get_text() -> String:
    return "Death has +2 Level if you control no other Minions."


func get_picture_index() -> int:
    return 139


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func get_level(playing_field, card) -> int:
    var starting_level = super.get_level(playing_field, card)
    var friendly_minion_count = playing_field.get_minion_strip(card.owner).cards().card_count()
    return starting_level + (2 if friendly_minion_count == 1 else 0)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var controls_minions = Query.on(playing_field).minions(player).any()
    if not controls_minions:
        score += 2 * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType):
        return score

    # If we control Death, then playing another Minion may reduce his
    # effectiveness.
    var death_morale = get_morale(playing_field, this_card)
    var max_morale_from_others = (
        Query.on(playing_field).minions(player)
        .filter(Query.not_equals(this_card))
        .map_max(Query.morale().value(), 0)
    )
    var new_minion_morale = target_card_type.get_base_morale()
    if new_minion_morale > max_morale_from_others:
        var value_lost = 2 * (mini(new_minion_morale, death_morale) - mini(max_morale_from_others, death_morale))
        score -= value_lost * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
