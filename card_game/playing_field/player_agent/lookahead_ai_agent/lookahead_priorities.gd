class_name LookaheadPriorities
extends RefCounted

# Class for a LookaheadAIAgent's priorities.
#
# This class can be thought of as a glorified read-only dictionary,
# whose keys are the constant StringNames defined in this file.
#
# All values in a LookaheadPriorities dictionary should generally be
# nonnegative. The AI will convert the values to negatives when it's
# performing an action contrary to the AI's goal. For instance, the
# "EVIL_POINT" priority is the value of one Evil Point. The AI will
# always negate that value when planning to spend Evil Points.

# Value of gaining one Evil Point, or equivalently the negative of the
# value of spending one Evil Point. This should almost always take on
# its default value of 1.0.
const EVIL_POINT := &"EVIL_POINT"

# Value of dealing one point of damage to the enemy's base, or
# equivalently, the value of healing one point of damage to the
# player's base.
const FORT_DEFENSE := &"FORT_DEFENSE"

# The value of successfully activating Destiny's Song. The default
# value for this is 20.0, or one third of the total fort defense.
const DESTINY_SONG := &"DESTINY_SONG"

# Value of increasing hand limit by one, for one turn.
const HAND_LIMIT_UP := &"HAND_LIMIT_UP"

# Value of drawing an extra card to the hand, as a special effect.
const EFFECT_DRAW := &"EFFECT_DRAW"

# The value of being able to draw AT LEAST one card during the
# starting draw phase of the next turn. This value is generally larger
# than NORMAL_DRAW, since the AI wants to avoid having its hand full
# at the end of its turn.
const FIRST_DRAW := &"FIRST_DRAW"

# The value of being able to draw additional cards (after FIRST_DRAW)
# as the default starting action of next turn.
const NORMAL_DRAW := &"NORMAL_DRAW"

# The opportunity cost of leaving an Evil Point on the table at the
# end of a turn.
const EVIL_POINT_OPPORTUNITY := &"EVIL_POINT_OPPORTUNITY"

# The value of a friendly Minion getting immunity to enemy card
# effects, such as through Ninja Mask or Cover of Moonlight.
#
# NOTE: This is not "per Minion". This valuation will be multiplied by
# the Minion's own "protection score", which for most Minions is
# "Level * Morale". This is because more powerful Minions are more
# valuable to protect with immunity effects.
const IMMUNITY := &"IMMUNITY"

# The value of playing an UNDEAD Minion, applied once per Minion. A
# naive valuation always puts UNDEAD Minions at -1.0, since they lose
# to curve by design. But playing an UNDEAD Minion has value for
# anyone playing an UNDEAD deck, so this value can offset that.
# Default value is 0.0.
const UNDEAD := &"UNDEAD"

# The value of converting an opponent card to a CLOWN Minion. Most
# decks don't care about this, so the default value is 0.0. But
# characters running a CLOWN deck will care.
const CLOWNING = &"CLOWNING"

# The value of converting a friendly Minion to a DEMON Minion. Most
# decks don't care about this, so the default value is 0.0, but
# characters running a DEMON deck will care.
const BEDEVILING = &"BEDEVILING"

# The value of converting a friendly Minion to a ROBOT Minion. Most
# decks don't care about this, so the default value is 0.0, but
# characters running a ROBOT deck will care.
const ROBOTING = &"ROBOTING"

const DEFAULT_PRIORITIES := {
    &"EVIL_POINT": 1.0,
    &"FORT_DEFENSE": 1.0,
    &"DESTINY_SONG": 20.0,
    &"HAND_LIMIT_UP": 0.3,
    &"EFFECT_DRAW": 0.6,
    &"FIRST_DRAW": 2.5,
    &"NORMAL_DRAW": 1.1,
    &"EVIL_POINT_OPPORTUNITY": 0.3,
    &"IMMUNITY": 0.15,
    &"UNDEAD": 0.0,
    &"CLOWNING": 0.0,
    &"BEDEVILING": 0.0,
    &"ROBOTING": 0.0,
}

var _data: Dictionary

func _init(data: Dictionary) -> void:
    _data = data
    _data.merge(DEFAULT_PRIORITIES, false)


func of(key: StringName) -> float:
    return float(_data[key])
