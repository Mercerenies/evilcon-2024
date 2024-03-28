class_name CardEffects
extends Node

# Helpers for code that gets reused across several playing card
# effects.

static func power_up_archetype(playing_field, source_card, archetype) -> void:
    var minions = CardGameApi.get_minions_in_play(playing_field)
    for minion in minions:
        var archetypes = minion.card_type.get_archetypes(playing_field, minion)
        if not archetype in archetypes:
            continue
        var can_influence = await minion.card_type.do_influence_check(playing_field, minion, source_card)
        if can_influence:
            Stats.add_level(playing_field, minion, 1)
