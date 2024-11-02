extends MinionCardType


func get_id() -> int:
    return 97


func get_title() -> String:
    return "Venomatrix"


func get_text() -> String:
    return "Venomatrix has +1 Level for each friendly [icon]BEE[/icon] BEE Minion in play (including Venomatrix)."


func get_level(playing_field, card) -> int:
    var friendly_minions = playing_field.get_minion_strip(card.owner).cards().card_array()
    var friendly_bees = friendly_minions.filter(func(minion):
        return minion.has_archetype(playing_field, Archetype.BEE))
    var starting_level = super.get_level(playing_field, card)
    return starting_level + len(friendly_bees)


func get_picture_index() -> int:
    return 55


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.BEE, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


@warning_ignore("CONFUSABLE_LOCAL_DECLARATION")
func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var base_score = super.ai_get_score(playing_field, player, priorities)
    var this_card_morale = get_base_morale()
    # Note: +Morale because Venomatrix counts herself when in play.
    var friendly_bee_count = get_base_morale() + (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.BEE))
        .map(func (playing_field, card): return mini(this_card_morale, card.card_type.get_morale(playing_field, card)))
        .reduce(Operator.plus, 0)
    )
    return base_score + friendly_bee_count * priorities.of(LookaheadPriorities.FORT_DEFENSE)


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # BEE Minions power up Venomatrix.
    if target_card_type is MinionCardType:
        if Archetype.BEE in target_card_type.get_base_archetypes():
            var turns_on_board_together = mini(get_morale(playing_field, this_card), target_card_type.get_base_morale())
            score += turns_on_board_together * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
