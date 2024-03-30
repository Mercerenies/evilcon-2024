class_name MinionCardType
extends CardType


func get_base_archetypes() -> Array:
    push_warning("Forgot to override get_base_archetypes!")
    return []


func get_archetypes(_playing_field, _card) -> Array:
    var base = get_base_archetypes()
    # TODO Consider extra archetypes added to the specific card
    return base


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


func on_expire(_playing_field, _card) -> void:
    pass


func get_overlay_text(playing_field, card) -> String:
    var level = get_level(playing_field, card)
    var morale = get_morale(playing_field, card)
    return "%s / %s" % [level, morale]


func on_attack_phase(playing_field, card) -> void:
    # By default, a Minion of Level > 0 attacks during the attack
    # phase.
    if playing_field.turn_player == card.owner:
        var level = get_level(playing_field, card)
        if level > 0:
            var opponent = CardPlayer.other(card.owner)
            await CardGameApi.highlight_card(playing_field, card)
            await Stats.add_fort_defense(playing_field, opponent, - level)
            # TODO Check if fort defense has hit zero


func on_morale_phase(playing_field, card) -> void:
    # By default, a Minion decreases Morale during the morale phase.
    if playing_field.turn_player == card.owner:
        await Stats.add_morale(playing_field, card, -1)
