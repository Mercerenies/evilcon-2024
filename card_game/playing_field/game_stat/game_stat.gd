@tool
extends Node2D

@export var icon: int = 0:
    get:
        return $CardIcon.frame
    set(v):
        $CardIcon.frame = v

@export var text: String = "Stat Text":
    get:
        return $Label.text
    set(v):
        $Label.text = v
