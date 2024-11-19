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
const DESTINYS_SONG := &"DESTINYS_SONG"

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

# The value of getting an extra attack from an UNDEAD Minion. This is
# applied once per Minion that will attack, regardless of that
# Minion's Level. The default value is 0.0, since a Minion already
# assumes that it will eventually get all of its attacks, but UNDEAD
# decks benefit from expediting this process so that cards like
# Graveyard Dance and Call of Ectoplasm have more targets.
const UNDEAD_BONUS_ATTACK := &"UNDEAD_BONUS_ATTACK"

# The value of converting an opponent card to a CLOWN Minion. Most
# decks don't care about this, so the default value is 0.0. But
# characters running a CLOWN deck will care.
const CLOWNING := &"CLOWNING"

# The value of converting a friendly Minion to a DEMON Minion. Most
# decks don't care about this, so the default value is 0.0, but
# characters running a DEMON deck will care.
const BEDEVILING := &"BEDEVILING"

# The value of converting a friendly Minion to a ROBOT Minion. Most
# decks don't care about this, so the default value is 0.0, but
# characters running a ROBOT deck will care.
const ROBOTING := &"ROBOTING"

# The value of eliminating an active hero check. Currently, the only
# active hero check in the game is Damsel in Distress. Most decks
# don't care very much about eliminating hero checks, but decks
# centered around Hero cards (and especially decks centered around
# Destiny's Song) will value this more.
const ELIMINATE_HERO_CHECK := &"ELIMINATE_HERO_CHECK"

# The value of drawing a Hero card out of your deck. Normal decks
# consider this equivalent to an EFFECT_DRAW, while Destiny's Song
# decks will value this higher.
const HERO_SCRY := &"HERO_SCRY"

# The value of successfully playing a hostage card to block Hero
# effects.
const HOSTAGE := &"HOSTAGE"

# The value of eliminating a card in the opponent's hand, or the
# negative of the value of being made to discard a card from the
# owner's hand.
const CARD_IN_HAND := &"CARD_IN_HAND"

# The value cost of exiling one's own card as part of that card's own
# effect.
const SINGLE_USE_EXILE := &"SINGLE_USE_EXILE"

# The value of exiling a random card from the opponent's deck, with no
# knowledge of what that card is.
const BLIND_EXILE := &"BLIND_EXILE"

# The value, per Level * Morale, of exiling a specific Minion of your
# own.
const DOOMED_EXILE := &"DOOMED_EXILE"

# The value of playing cards in the "right" order. This one is a bit
# unusual. If the AI knows that it can play two cards X and Y this
# turn in either order, but it's better to play X before Y, this is
# the value of playing X before Y instead of Y before X. Generally,
# this should just be a high number, since it's settling ties between
# a clearly better move and a clearly worse one.
const RIGHT_ORDER := &"RIGHT_ORDER"

const DEFAULT_PRIORITIES := {
    &"EVIL_POINT": 1.0,
    &"FORT_DEFENSE": 1.0,
    &"DESTINYS_SONG": 20.0,
    &"HAND_LIMIT_UP": 0.3,
    &"EFFECT_DRAW": 0.6,
    &"FIRST_DRAW": 2.5,
    &"NORMAL_DRAW": 0.8,
    &"EVIL_POINT_OPPORTUNITY": 0.1,
    &"IMMUNITY": 0.15,
    &"UNDEAD": 0.0,
    &"UNDEAD_BONUS_ATTACK": 0.0,
    &"CLOWNING": 0.0,
    &"BEDEVILING": 0.0,
    &"ROBOTING": 0.0,
    &"ELIMINATE_HERO_CHECK": 0.2,
    &"HERO_SCRY": 0.6,
    &"HOSTAGE": 2.5,
    &"CARD_IN_HAND": 0.4,
    &"SINGLE_USE_EXILE": 0.85,
    &"BLIND_EXILE": 4.0,
    &"DOOMED_EXILE": 0.7,
    &"RIGHT_ORDER": 10.0,
}

var _data: Dictionary

func _init(data: Dictionary) -> void:
    _data = data
    _data.merge(DEFAULT_PRIORITIES, false)


func of(key: StringName) -> float:
    return float(_data[key])
