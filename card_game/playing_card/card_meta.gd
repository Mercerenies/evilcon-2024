class_name CardMeta
extends Node

# Constant keys used in a card's metadata. All of the keys are kept
# here for organization purposes and to avoid confusion.
const LEVEL = &"LEVEL"
const MORALE = &"MORALE"
const TURN_COUNTER = &"TURN_COUNTER"
const ARCHETYPE_OVERRIDES = &"ARCHETYPE_OVERRIDES"
const SKIP_MORALE = &"SKIP_MORALE"

# A token card is a card that does not belong in a player's deck. A
# token is created from nothing and, when removed from the field for
# any reason, is exiled. That is, a token can never be placed in the
# deck, hand, or discard pile, and any attempts to do so will result
# in exiling the card instead.
const IS_TOKEN = &"IS_TOKEN"
