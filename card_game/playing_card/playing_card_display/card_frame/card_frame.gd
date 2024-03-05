extends Node2D

enum Frame {
    COMMON = 0,
    UNCOMMON = 1,
    RARE = 2,
    ULTRA_RARE = 3,
    DECK_ICON = 4,
    BLANK_ICON = 5,
}

var frame: int:
    get:
        return $Sprite2D.frame
    set(v):
        $Sprite2D.frame = v
