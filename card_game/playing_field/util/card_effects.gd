class_name CardEffects
extends Node

# Helpers for code that gets reused across several playing card
# effects.

# Powers up all Minions on the field which have the specified
# archetype.
static func power_up_archetype(playing_field, source_card, archetype) -> void:
    var minions = CardGameApi.get_minions_in_play(playing_field)
    for minion in minions:
        var archetypes = minion.card_type.get_archetypes(playing_field, minion)
        if not archetype in archetypes:
            continue
        var can_influence = await minion.card_type.do_influence_check(playing_field, minion, source_card)
        if can_influence:
            await Stats.add_level(playing_field, minion, 1)


# Performs the ninja influence check for the specified card.
static func do_ninja_influence_check(playing_field, target_card, source_card) -> bool:
    if target_card.owner != source_card.owner:
        var card_node = CardGameApi.find_card_node(playing_field, target_card)
        await Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": "Blocked!",
            "custom_label_color": Color.BLACK,
        })
        return false
    return true
