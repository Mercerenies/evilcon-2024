extends TimedCardType


func get_id() -> int:
    return 142


func get_title() -> String:
    return "No-Honk Zone"


func get_text() -> String:
    return "Enemy [icon]CLOWN[/icon] CLOWN Minions deal no damage to your fort. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 153


func get_rarity() -> int:
    return Rarity.UNCOMMON


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player who owns this card.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)

    if attacking_card.has_archetype(playing_field, Archetype.CLOWN):
        await CardGameApi.highlight_card(playing_field, this_card)
        var can_influence = attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
        if can_influence:  # TODO Consider if we can show this in the UI better, it's confusing right now
            Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
                "offset": 1,
            })
            return -99999
    return super.augment_attack_damage(playing_field, this_card, attacking_card)




func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)

    var opponent_minion_values = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter([Query.by_archetype(Archetype.CLOWN), Query.influenced_by(self, player)])
        .map_sum(func (playing_field, card): return _ai_get_blocked_value(playing_field, card, priorities))
    )
    score += opponent_minion_values

    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner == player or not (target_card_type is MinionCardType):
        return score  # Only look at opposing Minions
    if Archetype.CLOWN not in target_card_type.get_base_archetypes():
        return score  # Only clowns are affected

    # Decrease the value of playing by the length of time that No-Honk
    # Zone is still in play (minus one turn because No-Honk Zone
    # counts down before our next Attack Phase).
    var level = target_card_type.get_base_level()
    var morale = target_card_type.get_base_morale()
    var turns_left = get_total_turn_count() - this_card.metadata[CardMeta.TURN_COUNTER] - 1
    var turns_blocked = mini(morale, turns_left)

    score -= level * turns_blocked

    return score


func ai_get_score_per_turn(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score_per_turn(playing_field, player, priorities)
    # Assumes all Clowns currently in play will still be in play. This
    # is false, of course, but new Clowns can also be played (or
    # converted to) before that time, so it mostly balances out.
    var opponent_minion_values = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter([Query.by_archetype(Archetype.CLOWN), Query.influenced_by(self, player)])
        .map_sum(Query.level().value())
    )
    score += opponent_minion_values
    return score


func _ai_get_blocked_value(playing_field, card, priorities) -> float:
    var level = card.card_type.get_level(playing_field, card)
    var morale = card.card_type.get_morale(playing_field, card)
    var turns_blocked = mini(morale, get_total_turn_count())
    return turns_blocked * level * priorities.of(LookaheadPriorities.FORT_DEFENSE)
