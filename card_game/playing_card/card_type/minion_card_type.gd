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


func get_level(_playing_field, card) -> int:
    # TODO Card effects that passively modify this (as opposed to
    # instants that do so actively)
    #
    # IMPORTANT NOTE: Unlike many methods on CardType, get_level must
    # NOT `await`, as it will be called from contexts that cannot be
    # delayed, such as inside of Array.sort_custom.
    return card.metadata[CardMeta.LEVEL]


func get_morale(_playing_field, card) -> int:
    # This method is final and returns the concrete morale value at a
    # given moment. Card types are NOT permitted to modify the logic
    # for this method.
    return card.metadata[CardMeta.MORALE]


func get_stats_text() -> String:
    return "Lvl %s / %s Mor" % [get_base_level(), get_base_morale()]


func get_destination_strip(playing_field, owner: StringName):
    return playing_field.get_minion_strip(owner)


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


func on_expire(playing_field, card) -> void:
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

            await Stats.add_fort_defense(playing_field, opponent, - level)
            # TODO Check if fort defense has hit zero


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
