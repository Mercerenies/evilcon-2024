@tool
extends Node2D

const ICON_WIDTH = 28
const ICON_HEIGHT = 28

const ICONS_PER_ROW = 5

enum Frame {
    # Icon used for EP costs and player's current EP.
    EVIL_STAR = 0,
    # Tribe: HUMAN
    HUMAN = 1,
    # Tribe: NATURE
    NATURE = 2,
    # Tribe: TURTLE
    TURTLE = 3,
    # Tribe: SHAPE
    SHAPE = 4,
    # Tribe: PASTA
    PASTA = 5,
    # Tribe: CLOWN
    CLOWN = 6,
    # Tribe: ROBOT
    ROBOT = 7,
    # Tribe: BEE
    BEE = 8,
    # Tribe: NINJA
    NINJA = 9,
    # Unused icon (previously UNDEAD tribe)
    SKULL_UNUSED_ICON = 10,
    # Tribe: BOSS
    BOSS = 11,
    # Tribe: UNDEAD
    UNDEAD = 12,
    # Rarity: Common
    COMMON = 13,
    # Rarity: Uncommon
    UNCOMMON = 14,
    # Rarity: Rare
    RARE = 15,
    # Rarity: Ultra Rare
    ULTRA_RARE = 16,
    # Icon for fortress defense.
    FORT = 17,
    # Icon for hand limit.
    CARDS = 18,
    # Icon for amount of money.
    MONEY = 19,
    # Icon for Destiny's Song plays.
    SONG = 20,
    # Archetype-row icon for Limited cards (cards which can only exist
    # once per deck)
    LIMITED = 21,
    # Tribe: FARM
    FARM = 22,
    # Icon for token cards, which were created by another effect but
    # do not belong in the deck. Tokens are exiled when they leave the
    # field.
    TOKEN = 23,
    # Tribe: DEMON
    DEMON = 24,
    # Icon for cards with artificial NINJA-like effect immunity, even
    # if the card in question wouldn't normally have that immunity.
    #
    # Example: Ultimate Fusion
    IMMUNITY = 25,
    # Icon for cards which will be exiled when they leave the field
    # but which are not tokens.
    #
    # Example: Last Stand
    DOOMED = 26,
    # All tribes at once. A card with this icon counts as
    # *everything*.
    WILDCARD = 27,
}

var frame: int = 0:
    get:
        return $Sprite2D.frame
    set(v):
        $Sprite2D.frame = v
