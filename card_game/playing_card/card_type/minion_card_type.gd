class_name MinionCardType
extends CardType


func get_base_archetypes() -> Array:
    push_warning("Forgot to override get_base_archetypes!")
    return []


func get_archetypes(_playing_field, card) -> Array:
    var base = get_base_archetypes()
    var overrides = card.metadata[CardMeta.ARCHETYPE_OVERRIDES]
    return overrides if overrides != null else base


func get_icon_row() -> Array:
    return super.get_icon_row() + get_base_archetypes().map(Archetype.to_icon_index)


func get_base_level() -> int:
    push_warning("Forgot to override get_base_level!")
    return 0


func get_base_morale() -> int:
    push_warning("Forgot to override get_base_morale!")
    return 0


func get_level(playing_field, card) -> int:
    # IMPORTANT NOTE: Unlike many methods on CardType, get_level must
    # NOT `await`, as it will be called from contexts that cannot be
    # delayed, such as inside of Array.sort_custom.
    var level = card.metadata[CardMeta.LEVEL]
    for augmentation in CardGameApi.broadcast_to_cards(playing_field, "get_level_modifier", [card]):
        level += augmentation
    if level >= 0:
        return level
    else:
        return 0


func get_morale(_playing_field, card) -> int:
    # This method is final and returns the concrete morale value at a
    # given moment. Card types are NOT permitted to modify the logic
    # for this method.
    return card.metadata[CardMeta.MORALE]


func get_stats_text() -> String:
    return "Lvl %s / %s Mor" % [get_base_level(), get_base_morale()]


func get_destination_strip(playing_field, owner: StringName):
    return playing_field.get_minion_strip(owner)


func is_spiky(playing_field, this_card) -> bool:
    # Returns true if this card counts as Spiky. "Spiky" is not an
    # archetype. The general rule is: A card counts as Spiky if and
    # only if the word "Spiky" appears in the card's name. However,
    # this is a broadcasting method, so any and all cards in play have
    # an opportunity to override this behavior.
    #
    # It is only possible to increase the spiky-ness of a card. It is
    # not possible, under the current implementation, to "remove" the
    # spiky-ness from a Minion card. If we decide to implement such
    # effects, we will update this implementation to reflect the new
    # functionality.
    #
    # This method MUST NOT await.
    if "Spiky" in this_card.card_type.get_title():
        return true
    var all_cards = CardGameApi.get_cards_in_play(playing_field)
    for card in all_cards:
        if card.card_type.is_spiky_broadcasted(playing_field, card, this_card):
            return true
    return false


func on_instantiate(card) -> void:
    super.on_instantiate(card)
    # Initialize Level and Morale.
    card.metadata[CardMeta.LEVEL] = get_base_level()
    card.metadata[CardMeta.MORALE] = get_base_morale()
    # Minions initially have no archetype overrides. If this value
    # becomes non-null, it must be an array of archetypes to replace
    # the Minion's default archetypes.
    card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = null
    # This flag is normally never set. But a few cards summon Minions
    # during the Attack Phase, and it makes little sense to decrement
    # their morale during the current turn in that case. So cards that
    # do so (like Farmer Blue) will set this flag, which skips the
    # Minion's first Morale Phase.
    card.metadata[CardMeta.SKIP_MORALE] = false


func on_pre_expire(playing_field, card) -> void:
    # When a Minion hits zero Morale, it is normally destroyed. Before
    # committing to the destruction, on_pre_expire is called. The
    # default behavior of this method is to broadcast the
    # intent-to-expire to all other Minion and Effect cards.
    #
    # This method is called prior to on_expire, before the Minion has
    # committed to being destroyed. If on_pre_expire or
    # on_pre_expire_broadcasted causes the Minion to re-gain Morale,
    # then it will be preserved.
    #
    # All subclass implementations MUST invoke this superclass method,
    # to ensure proper broadcasting. This method may await.
    #
    # See the documentation for on_expire for details on the
    # expiration lifecycle.
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_pre_expire_broadcasted", [card])


func on_expire(playing_field, card) -> void:
    # When a Minion hits zero Morale, it is destroyed, and immediately
    # before being destroyed in this fashion, on_expire is called. The
    # default behavior of this method is to broadcast the expiration
    # to all other cards (not just Minions but also Effect cards).
    #
    # Note that, when this method is called, the Minion has already
    # committed to being destroyed. Even if the on_expire event causes
    # the Minion to re-gain Morale, it will still be destroyed.
    #
    # All subclass implementations MUST invoke this superclass method,
    # to ensure proper broadcasting. This method may await.
    #
    # The specific lifecycle for Minion expiration is as follows.
    #
    # 1. A Minion card has its Morale set to zero, either during the
    # Morale Phase or due to some other effect.
    #
    # 2. The Minion recognizes that it has hit zero Morale and
    # prepares to expire. The Minion invokes on_pre_expire, which also
    # calls on_pre_expire_broadcasted on all cards in play.
    #
    # 3. The Minion checks if the pre-expire call caused it to gain
    # Morale. If so, this process is terminated, and the Minion
    # survived. Otherwise, the Minion commits to being destroyed.
    #
    # 4. The Minion calls on_expire, which in turn calls
    # on_expire_broadcasted on all cards in play.
    #
    # 5. The Minion is destroyed, regardless of its final Morale
    # value.
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_expire_broadcasted", [card])


func get_overlay_text(playing_field, card) -> String:
    var level = get_level(playing_field, card)
    var morale = get_morale(playing_field, card)
    return "%s / %s" % [level, morale]


func on_attack_phase(playing_field, card) -> void:
    await super.on_attack_phase(playing_field, card)
    # By default, a Minion of Level > 0 attacks during the Attack
    # Phase.
    if playing_field.turn_player == card.owner:
        var level = get_level(playing_field, card)
        if level > 0:
            var opponent = CardPlayer.other(card.owner)
            await CardGameApi.highlight_card(playing_field, card)

            # Check if anything blocks the Attack Phase.
            var should_proceed = await CardEffects.do_attack_phase_check(playing_field, card)
            if not should_proceed:
                return

            var damage = level
            for augmentation in await CardGameApi.broadcast_to_cards_async(playing_field, "augment_attack_damage", [card]):
                damage += augmentation
            if damage > 0:
                await Stats.add_fort_defense(playing_field, opponent, - damage)


func on_morale_phase(playing_field, card) -> void:
    await super.on_morale_phase(playing_field, card)
    # By default, a Minion decreases Morale during the Morale Phase.
    if playing_field.turn_player == card.owner:
        if card.metadata[CardMeta.SKIP_MORALE]:
            card.metadata[CardMeta.SKIP_MORALE] = false
            return

        var should_proceed = await CardEffects.do_morale_phase_check(playing_field, card)
        if not should_proceed:
            return

        await Stats.add_morale(playing_field, card, -1)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    score += get_base_level() * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    if Archetype.UNDEAD in get_base_archetypes():
        score += priorities.of(LookaheadPriorities.UNDEAD)
    return score


# Gets the expected remaining value, in fort defense points, of this
# Minion. Usually, this is Level * Morale, but some Minions who have
# unusual Attack Phases may have different valuations. Additionally,
# Minions who do something when they expire may have a valuation
# higher than usual.
#
# `card` can be null. If `card` is null, then the question is being
# asked for a card that is not yet in play. All overrides of this
# method MUST support both null and non-null `card` values.
func ai_get_expected_remaining_score(playing_field, card) -> float:
    if card == null:
        return get_base_level() * get_base_morale()
    else:
        return get_level(playing_field, card) * get_morale(playing_field, card)


# Gets the value of the owner voluntarily destroying this Minion.
# Normally, this is just ai_get_expected_remaining_score times the
# appropriate priority, but UNDEAD Minions may also get a decrease to
# this number, since UNDEAD Minions benefit from being in the discard
# pile.
#
# `card` can be null.
func ai_get_value_of_destroying(playing_field, card, priorities) -> float:
    var is_undead
    if card == null:
        is_undead = (Archetype.UNDEAD in get_base_archetypes())
    else:
        is_undead = card.has_archetype(playing_field, Archetype.UNDEAD)
    var score = ai_get_expected_remaining_score(playing_field, card) * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    if is_undead:
        score -= priorities.of(LookaheadPriorities.UNDEAD_DESTRUCTION)
    return score


# Should return true if this card (in hand) WOULD be spiky if played
# right now.
#
# This method MUST NOT await.
func ai_will_be_spiky(playing_field, owner):
    if "Spiky" in get_title():
        return true
    var all_cards = CardGameApi.get_cards_in_play(playing_field)
    for card in all_cards:
        if card.card_type.ai_will_be_spiky_broadcasted(playing_field, card, self, owner):
            return true
    return false
