class_name MinionCardType
extends CardType


func get_archetypes() -> Array:
    push_warning("Forgot to override get_archetypes!")
    return []


func get_icon_row() -> Array:
    return super.get_icon_row() + get_archetypes().map(Archetype.to_icon_index)


func get_base_level() -> int:
    push_warning("Forgot to override get_base_level!")
    return 0


func get_base_morale() -> int:
    push_warning("Forgot to override get_base_morale!")
    return 0


func get_level(_playing_field, card) -> int:
    # TODO Card effects that passively modify this (as opposed to
    # instants that do so actively)
    return card.metadata[CardMeta.LEVEL]


func get_morale(_playing_field, card) -> int:
    # TODO Card effects that passively modify this (as opposed to
    # instants that do so actively)
    return card.metadata[CardMeta.MORALE]


func get_stats_text() -> String:
    return "Lvl %s / %s Mor" % [get_base_level(), get_base_morale()]


func get_destination_strip(playing_field, owner: StringName):
    return playing_field.get_minion_strip(owner)


func on_play(_playing_field, _card) -> void:
    # Default implementation for minions is to have no "on play"
    # effect. Specific minion card types can override this if they so
    # choose.
    pass


func on_instantiate(card) -> void:
    super.on_instantiate(card)
    # Initialize Level and Morale.
    card.metadata[CardMeta.LEVEL] = get_base_level()
    card.metadata[CardMeta.MORALE] = get_base_morale()


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
            Stats.add_fort_defense(playing_field, opponent, - level)
            # TODO Check if fort defense has hit zero


func on_morale_phase(playing_field, card) -> void:
    # By default, a Minion decreases Morale during the morale phase.
    if playing_field.turn_player == card.owner:
        card.metadata[CardMeta.MORALE] -= 1
        if card.metadata[CardMeta.MORALE] <= 0:
            await CardGameApi.destroy_card(playing_field, card)
