extends MinionCardType


func get_id() -> int:
    return 129


func get_title() -> String:
    return "The Devil"


func get_text() -> String:
    return "When The Devil expires, convert all friendly Minions to [icon]DEMON[/icon] DEMON Minions."


func get_picture_index() -> int:
    return 121


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.DEMON, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var owner = this_card.owner
    var minion_strip = playing_field.get_minion_strip(owner)
    await CardGameApi.highlight_card(playing_field, this_card)

    if minion_strip.cards().card_count() <= 1:  # <= 1 because this card is still in play.
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        for minion in minion_strip.cards().card_array():
            if minion == this_card:
                continue
            Stats.show_text(playing_field, minion, PopupText.DEMONED)
            minion.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.DEMON]
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var devil_morale = get_base_morale()

    # Count the Minions that will still be in play when the Devil expires.
    var non_demons_still_in_play = (
        Query.on(playing_field).minions(player)
        .filter(func (playing_field, card): return card.card_type.get_morale(playing_field, card) > devil_morale)
        .count(Query.not_(Query.by_archetype(Archetype.DEMON)))
    )
    score += non_demons_still_in_play * priorities.of(LookaheadPriorities.BEDEVILING)

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score
    if not (target_card_type is MinionCardType) or Archetype.DEMON in target_card_type.get_base_archetypes():
        return score

    # If we control The Devil, then playing non-DEMONs is a good idea,
    # because The Devil will convert them.
    if target_card_type.get_base_morale() > get_morale(playing_field, this_card):
        score += priorities.of(LookaheadPriorities.BEDEVILING)

    return score
