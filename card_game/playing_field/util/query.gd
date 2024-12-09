class_name Query
extends Node

# ActiveRecord-style query API for cards currently on the board.

class Q:
    # Array wrapper that supports the query API and has access to a PlayingField
    var _playing_field
    var _impl: Array

    func _init(playing_field, arr: Array) -> void:
        _playing_field = playing_field
        _impl = arr

    func array() -> Array:
        return _impl

    func reversed():
        var arr = array().duplicate()
        arr.reverse()
        return Q.new(_playing_field, arr)

    func filter(callable_or_arr):
        # Filters the array. The callable shall take two arguments:
        # the playing field and the particular card or card type to
        # inspect.
        if callable_or_arr is Array:
            callable_or_arr = Query.and_(callable_or_arr)
        return Q.new(_playing_field, array().filter(
            func (card): return callable_or_arr.call(_playing_field, card)
        ))

    func slice(begin = 0, end = 2147483647, step = 1):
        return Q.new(_playing_field, array().slice(begin, end, step))

    func map(callable):
        # Maps a callable over the query, returning an array. NOTE:
        # This method does NOT return a Q, since the map might return
        # things other than cards.
        return array().map(func(card): return callable.call(_playing_field, card))

    func map_sum(callable):
        # Equivalent to .map, followed by summing the resulting array.
        # The callable must produce numerical values.
        return map(callable).reduce(Operator.plus, 0)

    func map_max(callable, default = null):
        if default == null:
            return map(callable).max()
        else:
            return map(callable).reduce(func (a, b): return max(a, b), default)

    func map_min(callable, default = null):
        if default == null:
            return map(callable).min()
        else:
            return map(callable).reduce(func (a, b): return min(a, b), default)

    func index_of(callable):
        # Returns the index of the first card that matches the given
        # callable, or null if not found.
        return Util.find_if(array(), func(card): return callable.call(_playing_field, card))

    func find(callable):
        var index = index_of(callable)
        return null if index == null else array()[index]

    func any(callable = null):
        # Returns true if any element matches the callable.
        if callable == null:
            callable = Query.always_true
        return (index_of(callable) != null)

    func count(callable = null):
        if callable == null:
            return len(array())
        else:
            return filter(callable).count()

    func max():
        return Util.max_by(array(), CardEffects.card_power_less_than(_playing_field))

    func min():
        return Util.min_by(array(), CardEffects.card_power_less_than(_playing_field))

    func max_by(callable):
        return Util.max_by(array(), func(card): return callable.call(_playing_field, card))

    func min_by(callable):
        return Util.min_by(array(), func(card): return callable.call(_playing_field, card))

    func random():
        # Using the playing field's random number generator, pick a
        # random card. Returns null if the query is empty.
        if len(array()) == 0:
            return null
        else:
            return _playing_field.randomness.choose(array())


class QueryManager:
    # Helper class to initiate a query on a specific part of the
    # board.
    var _playing_field

    func _init(playing_field) -> void:
        _playing_field = playing_field

    # Query on cards in play. If `player` is supplied, this also
    # functions as an ownership filter.
    func cards(player = null):
        var q = Q.new(_playing_field, CardGameApi.get_cards_in_play(_playing_field))
        if player != null:
            q = q.filter(Query.by_owner(player))
        return q

    # Query on Minions in play. Optionally filter by owner as well.
    func minions(player = null):
        return cards(player).filter(Query.is_minion)

    # Query on Effects in play. Optionally filter by owner as well.
    func effects(player = null):
        return cards(player).filter(Query.is_effect)

    # Query on cards in the given player's hand. Player is NOT
    # optional.
    func hand(player: StringName):
        var cards = _playing_field.get_hand(player).cards().card_array()
        return Q.new(_playing_field, cards)

    # Query on cards in the given player's deck from top to bottom.
    # Player is NOT optional.
    func deck(player: StringName):
        var cards = _playing_field.get_deck(player).cards().card_array()
        return Q.new(_playing_field, cards).reversed()  # Top to bottom

    # Query on cards in the given player's discard pile, from top to
    # bottom. Player is NOT optional.
    func discard_pile(player: StringName):
        var cards = _playing_field.get_discard_pile(player).cards().card_array()
        return Q.new(_playing_field, cards).reversed()  # Top to bottom

    # Query on all cards owned by the given player except those which
    # have been exiled. This includes the player's hand, deck, field,
    # and discard pile. This will be a mixed array of Card and
    # CardType objects.
    #
    # The order of elements in the returned array is NOT guaranteed.
    # Player is NOT optional.
    func full_deck(player: StringName):
        var all_cards = []
        all_cards.append_array(_playing_field.get_hand(player).cards().card_array())
        all_cards.append_array(_playing_field.get_deck(player).cards().card_array())
        all_cards.append_array(_playing_field.get_discard_pile(player).cards().card_array())
        all_cards.append_array(_playing_field.get_minion_strip(player).cards().card_array())
        all_cards.append_array(_playing_field.get_effect_strip(player).cards().card_array())
        return Q.new(_playing_field, all_cards)


# All queries must start with a call to this method, which returns a
# QueryManager object representing every card on the board, regardless
# of owner.
static func on(playing_field) -> QueryManager:
    return QueryManager.new(playing_field)

## Various helper filter functions, each of which satisfies the
## signature of Q.filter.

# Filter by owner. Cards not on the field (i.e. in a player's hand,
# deck, or discard pile) do not have owners and will always fail this
# predicate.
static func by_owner(player: StringName):
    return func filter_by_owner(_playing_field, card):
        if card is CardType:
            return false
        else:
            return card.owner == player


# Filter by original owner. Cards not on the field (i.e. in a player's
# hand, deck, or discard pile) do not have owners and will always fail
# this predicate.
static func by_original_owner(player: StringName):
    return func filter_by_original_owner(_playing_field, card):
        if card is CardType:
            return false
        else:
            return card.original_owner == player


# Filter by archetype. For Minions in play, this takes archetype
# overrides into consideration.
#
# Effect cards have no archetype and always fail this predicate.
static func by_archetype(archetype_or_arr):
    if archetype_or_arr is Array:
        return or_(archetype_or_arr.map(func (a): return by_archetype(a)))
    else:
        var archetype = archetype_or_arr
        return func filter_by_archetype(playing_field, card):
            if card is CardType:
                return card is MinionCardType and archetype in card.get_base_archetypes()
            else:
                return card.card_type is MinionCardType and card.has_archetype(playing_field, archetype)


static func by_id(id):
    if id is Array:
        return or_(id.map(func (i): return by_id(i)))
    return func filter_by_id(_playing_field, card):
        if card is CardType:
            return card.get_id() == id
        else:
            return card.card_type.get_id() == id


# Filter down to cards which can be influenced by this card. Performs
# a CardEffects.do_hypothetical_influence_check.
#
# Cards not in play can always be influenced, since they don't undergo
# influence checks normally (For instance, Skunkman can force you to
# discard cards, regardless of how many ninja protections you have).
static func influenced_by(activating_card_type, player: StringName):
    return func filter_by_influence_check(playing_field, target_card):
        if target_card is CardType:
            return true
        else:
            return CardEffects.do_hypothetical_influence_check(playing_field, target_card, activating_card_type, player)


# Filter to Minions.
static func is_minion(_playing_field, card):
    if card is CardType:
        return card is MinionCardType
    else:
        return card.card_type is MinionCardType


# Filter to Effects.
static func is_effect(_playing_field, card):
    if card is CardType:
        return card is EffectCardType
    else:
        return card.card_type is EffectCardType


# Filter to timed effects.
static func is_timed_effect(_playing_field, card):
    if card is CardType:
        return card is TimedCardType
    else:
        return card.card_type is TimedCardType


# Filter to cards literally equal to the target.
static func equals(target_card):
    return func filter_by_equality(_playing_field, card):
        return card == target_card


static func not_equals(target_card):
    return not_(equals(target_card))


# Complement of predicate.
static func not_(pred):
    return func negated_predicate(playing_field, card):
        return not pred.call(playing_field, card)


static func always_true(_playing_field, _card):
    return true


static func always_false(_playing_field, _card):
    return false


static func and_(preds: Array):
    return func conjunction(playing_field, card):
        for pred in preds:
            if not pred.call(playing_field, card):
                return false
        return true


static func or_(preds: Array):
    return func disjunction(playing_field, card):
        for pred in preds:
            if pred.call(playing_field, card):
                return true
        return false

## Filters predicated by a numerical value.

# Intermediate class for comparisons against common numerical values
# on cards. Instancees of this class SHOULD NOT be explicitly
# constructed outside of this file. Use the static helper functions
# defined below.
class NumericalCompare:
    var _getter: Callable

    func _init(getter: Callable):
        _getter = getter

    func greater_than(value):
        return func comparison(playing_field, card):
            return _getter.call(playing_field, card) > value

    func at_least(value):
        return func comparison(playing_field, card):
            return _getter.call(playing_field, card) >= value

    func less_than(value):
        return func comparison(playing_field, card):
            return _getter.call(playing_field, card) < value

    func at_most(value):
        return func comparison(playing_field, card):
            return _getter.call(playing_field, card) <= value

    # Returns the numerical value as an integer when queried. Useful
    # in map() and similar functions.
    func value():
        return _getter


static func morale() -> NumericalCompare:
    return NumericalCompare.new(func(playing_field, card):
        if card is CardType:
            return card.get_base_morale()
        else:
            return card.card_type.get_morale(playing_field, card))


static func level() -> NumericalCompare:
    return NumericalCompare.new(func(playing_field, card):
        if card is CardType:
            return card.get_base_level()
        else:
            return card.card_type.get_level(playing_field, card))


static func cost() -> NumericalCompare:
    return NumericalCompare.new(func(_playing_field, card):
        if card is CardType:
            return card.get_star_cost()
        else:
            return card.card_type.get_star_cost())


# Turns remaining on a TimedCardType. Zero for any card which is NOT a
# TimedCardType.
static func turn_count() -> NumericalCompare:
    return NumericalCompare.new(func(_playing_field, card):
        if card is CardType:
            return card.get_total_turn_count() if card is TimedCardType else 0
        else:
            if not (card.card_type is TimedCardType):
                return 0
            return card.card_type.get_total_turn_count() - card.metadata.get(CardMeta.TURN_COUNTER, 0))


static func remaining_ai_value() -> NumericalCompare:
    return NumericalCompare.new(func(playing_field, card):
        if card is CardType:
            if card is MinionCardType:
                return card.ai_get_expected_remaining_score(playing_field, null)
            else:
                return 0.0
        else:
            if card.card_type is MinionCardType:
                return card.card_type.ai_get_expected_remaining_score(playing_field, card)
            else:
                return 0.0)


static func value_of_destroying(priorities) -> NumericalCompare:
    return NumericalCompare.new(func(playing_field, card):
        if card is CardType:
            if card is MinionCardType:
                return card.ai_get_value_of_destroying(playing_field, null, priorities)
            else:
                return 0.0
        else:
            if card.card_type is MinionCardType:
                return card.card_type.ai_get_value_of_destroying(playing_field, card, priorities)
            else:
                return 0.0)
