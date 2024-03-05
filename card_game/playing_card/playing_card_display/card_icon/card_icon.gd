extends Node2D

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
}

var frame: int:
    get:
        return $Sprite2D.frame
    set(v):
        $Sprite2D.frame = v
