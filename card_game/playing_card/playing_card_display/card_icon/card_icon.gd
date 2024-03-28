@tool
extends Node2D

const ICON_WIDTH = 28
const ICON_HEIGHT = 28

const ICONS_PER_ROW = 5

enum Frame {
    EVIL_STAR = 0,
    HUMAN = 1,
    FUNGUS = 2,
    TURTLE = 3,
    SHAPE = 4,
    PASTA = 5,
    CLOWN = 6,
    ROBOT = 7,
    BEE = 8,
    NINJA = 9,
    SKULL_UNUSED_ICON = 10, # Unused icon
    BOSS = 11,
    ZOMBIE = 12,
    COMMON = 13,
    UNCOMMON = 14,
    RARE = 15,
    ULTRA_RARE = 16,
    FORT = 17,
    CARDS = 18,
    MONEY = 19,
    SONG = 20,
    LIMITED = 21,
}

var frame: int = 0:
    get:
        return $Sprite2D.frame
    set(v):
        $Sprite2D.frame = v
