extends MinionCardType


func get_id() -> int:
    return 113


func get_title() -> String:
    return "Icosaking"


func get_text() -> String:
    return "Enemy Level 1 Minions deal no damage to your fortress."


func get_picture_index() -> int:
    return 9


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.SHAPE, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player as
        # the Icosaking
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.card_type.get_level(playing_field, attacking_card) <= 1:
        await CardGameApi.highlight_card(playing_field, this_card)
        var can_influence = attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
        if can_influence:  # TODO Consider if we can show this in the
                           # UI better, it's confusing right now.
                           # Maybe rather than "Blocked", we say
                           # "Shielded" or something.
            Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
                "offset": 1,
            })
            return -99999
    return super.augment_attack_damage(playing_field, this_card, attacking_card)


@warning_ignore("CONFUSABLE_LOCAL_DECLARATION")
func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Enemy Level 1 Minions don't get to attack for the turns that
    # Icosaking is in play.
    var icosaking_morale = get_base_morale()
    var blocked_minion_turns = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .filter(func(playing_field, card): return card.card_type.get_level(playing_field, card) <= 1)
        .map(func(playing_field, card):
                 if not CardEffects.do_hypothetical_influence_check(playing_field, card, self, player):
                     return 0
                 return mini(icosaking_morale, card.card_type.get_morale(playing_field, card)))
        .reduce(Operator.plus, 0)
    )
    score += blocked_minion_turns * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
