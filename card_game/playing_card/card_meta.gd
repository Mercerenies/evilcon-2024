class_name CardMeta
extends Node

# Constant keys used in a card's metadata. All of the keys are kept
# here for organization purposes and to avoid confusion.

# Integer. A Minion's current base level. Includes permanent bonuses
# but excludes passive modifiers fueled by cards in play.
const LEVEL = &"LEVEL"

# Integer. A Minion's current morale.
const MORALE = &"MORALE"

# Integer. An effect's turn counter, for cards that have one. Starts
# at zero and counts up.
const TURN_COUNTER = &"TURN_COUNTER"

# Array of archetypes. Override for a Minion's archetypes. Replaces
# all base archetypes if present.
const ARCHETYPE_OVERRIDES = &"ARCHETYPE_OVERRIDES"

# Boolean. Set to true if the next Morale Phase should be skipped for
# this card. This value is almost always false. See
# MinionCardType.on_instantiate for the rationale behind this field.
const SKIP_MORALE = &"SKIP_MORALE"

# Boolean. A token card is a card that does not belong in a player's
# deck. A token is created from nothing and, when removed from the
# field for any reason, is exiled. That is, a token can never be
# placed in the deck, hand, or discard pile, and any attempts to do so
# will result in exiling the card instead.
const IS_TOKEN = &"IS_TOKEN"

# Boolean. Cards such as Ninjas naturally have immunity from enemy
# card effects. Those cards should NOT use this meta field. However,
# some effects will give cards immunity, when they didn't have it
# before. Those cards should use this field to indicate that the
# immunity modifier is present.
const HAS_SPECIAL_IMMUNITY = &"HAS_SPECIAL_IMMUNITY"

# Boolean. A doomed card is a card which will be exiled when it is
# removed from the field for any reason. A doomed card is similar to a
# token card, except that token cards do not originally belong to the
# player's deck, while a doomed card is a soon-to-be-exiled card that
# started out in the player's deck.
const IS_DOOMED = &"IS_DOOMED"
