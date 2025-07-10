extends TimedCardType


func get_id() -> int:
    return 180


func get_title() -> String:
    return "Alone in the Dark"


func get_text() -> String:
    return "If you control only one Minion, and that Minion is a [icon]DEMON[/icon] DEMON, it gets +2 Level. Lasts 3 turns."


func get_total_turn_count() -> int:
    return 3


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 186


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_level_modifier(playing_field, this_card, minion_card) -> int:
    var modifier = super.get_level_modifier(playing_field, this_card, minion_card)
    if this_card.owner != minion_card.owner:
        return modifier
    if not _owner_has_only_one_minion(playing_field, this_card.owner):
        return modifier
    if not minion_card.has_archetype(playing_field, Archetype.DEMON):
        return modifier
    return modifier + 2


func _owner_has_only_one_minion(playing_field, owner) -> bool:
    return playing_field.get_minion_strip(owner).cards().card_count() == 1


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    if _owner_has_only_one_minion(playing_field, player):
        var unique_minion = Query.on(playing_field).minions(player).first()
        if unique_minion.has_archetype(playing_field, Archetype.DEMON):
            var morale = unique_minion.card_type.get_morale(playing_field, unique_minion)
            score += 2 * mini(morale, get_total_turn_count()) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)

    if _owner_has_only_one_minion(playing_field, player):
        var unique_minion = Query.on(playing_field).minions(player).first()
        if unique_minion.has_archetype(playing_field, Archetype.DEMON):
            # Assume this Minion will be around long enough to get one extra turn.
            score += 2 * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType):
        return score

    var minion_count = Query.on(playing_field).minions(player).count()
    var turns_left = get_total_turn_count() - this_card.metadata[CardMeta.TURN_COUNTER]

    # If we control no Minions, then playing a DEMON will put it at +2 Level.
    if minion_count == 0 and Archetype.DEMON in target_card_type.get_base_archetypes():
        score += 2 * mini(target_card_type.get_base_morale(), turns_left) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    # If we already control one DEMON and nothing else, then playing a
    # new Minion *hurts* that DEMON.
    if minion_count == 1:
        var unique_minion = Query.on(playing_field).minions(player).first()
        if unique_minion.has_archetype(playing_field, Archetype.DEMON):
            var morale = unique_minion.card_type.get_morale(playing_field, unique_minion)
            score -= 2 * mini(morale, turns_left) * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
