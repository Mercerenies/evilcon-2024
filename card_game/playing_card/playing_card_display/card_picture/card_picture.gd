extends Node2D

var frame: int = 0:
    get:
        return $Sprite2D.frame
    set(v):
        $Sprite2D.frame = v
