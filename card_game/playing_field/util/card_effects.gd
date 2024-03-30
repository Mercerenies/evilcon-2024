class_name CardEffects
extends Node

# Helpers for code that gets reused across several playing card
# effects.

# Powers up all Minions on the field which have the specified
# archetype.
static func power_up_archetype(playing_field, source_card, archetype: int) -> void:
    var minions = CardGameApi.get_minions_in_play(playing_field)
    for minion in minions:
        if not minion.has_archetype(playing_field, archetype):
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
        }) # TODO Do we await this, or just fire-and-forget?
        return false
    return true


# The "less than" comparison operator for Minion cards by their
# "power" level. This is the comparison used by all of the card
# effects that refer to the "most powerful" or "least powerful" Minion
# in play. This is a valid total ordering, and two cards are
# considered equivalent under this ordering if and only if they have
# the same stats and the same card type.
#
# Specifically, this function takes a playing_field and returns a
# binary comparison operator, since the calculation depends on the
# state of the playing field (as some cards will influence the level
# of other cards in play).
#
# The ordering used here is as follows:
#
# * Compare the Minions' power (= Level * Morale).
#
# * In cases of equal power, compare Morale alone.
#
# * If all stats are equal, compare card type ID (as an arbitrary but
#   consistent tiebreaker).
#
# * If that fails, consider the two cards equivalent.
#
# This comparison only makes sense for Minions and shall not be
# applied to Effect cards.
static func card_power_less_than(playing_field) -> Callable:
    return func less_than(a, b) -> bool:
        var level_a = a.card_type.get_level(playing_field, a)
        var level_b = a.card_type.get_level(playing_field, b)
        var morale_a = a.card_type.get_morale(playing_field, a)
        var morale_b = a.card_type.get_morale(playing_field, b)
        if level_a * morale_a < level_b * morale_b:
            return true
        elif level_a * morale_a == level_b * morale_b:
            if morale_a < morale_b:
                return true
            elif morale_a == morale_b:
                return (a.card_type.get_id() < b.card_type.get_id())
            else:
                return false
        else:
            return false


# Returns the most powerful Minion currently in play. If player is
# non-null, only Minions belonging to that player will be considered.
# Otherwise, all Minions in play are considered.
#
# Returns null if there are no minions in play satisfying the
# condition.
static func most_powerful_minion(playing_field, player):
    var all_minions = CardGameApi.get_minions_in_play(playing_field)
    if player != null:
        all_minions = all_minions.filter(func (minion): return minion.owner == player)
    return Util.max_by(all_minions, card_power_less_than(playing_field))
