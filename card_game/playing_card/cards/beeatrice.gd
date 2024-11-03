extends MinionCardType


func get_id() -> int:
    return 187


func get_title() -> String:
    return "Beeatrice"


func get_text() -> String:
    return "When Beeatrice expires, all friendly [icon]BEE[/icon] BEE Minions gain 1 Morale."


func get_picture_index() -> int:
    return 198


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, card) -> void:
    await super.on_expire(playing_field, card)
    var owner = card.owner

    await CardGameApi.highlight_card(playing_field, card)

    var friendly_bees = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func (m): return m.has_archetype(playing_field, Archetype.BEE))
    )

    if len(friendly_bees) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        for minion in friendly_bees:
            await Stats.add_morale(playing_field, minion, 1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var beeatrice_morale = get_base_morale()
    var bee_levels = (
        Query.on(playing_field).minions(player)
        .filter([Query.by_archetype(Archetype.BEE), Query.morale().greater_than(beeatrice_morale)])
        .map_sum(Query.level().value())
    )
    score += bee_levels * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType) or not (Archetype.BEE in target_card_type.get_base_archetypes()):
        return score

    # If we control Beeatrice, then we should play BEE Minions.
    score += target_card_type.get_base_level() * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
