extends Node2D

var icon: int = 0:
    get:
        return $CardIcon.frame
    set(v):
        $CardIcon.frame = v

var text: String = "Stat Text":
    get:
        return $Label.text
    set(v):
        $Label.text = v
