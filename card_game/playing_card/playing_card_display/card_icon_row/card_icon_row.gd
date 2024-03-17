@tool
extends Node2D

const CardIconScene = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.tscn")
const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")

@export_enum("Left", "Right") var alignment = "Left":
    set(v):
        alignment = v
        _update_row()
@export var icons: Array = [CardIcon.Frame.EVIL_STAR]:
    set(v):
        icons = v
        _update_row()


func _update_row():
    Util.queue_free_all_children(self)
    var pos = Vector2.ZERO
    var iterable = icons.duplicate()
    var delta = Vector2(CardIcon.ICON_WIDTH, 0)
    if alignment == "Right":
        iterable.reverse()
        delta *= -1
    for icon_index in icons:
        var icon = CardIconScene.instantiate()
        icon.position = pos
        icon.frame = icon_index
        add_child(icon)
        pos += delta


func get_rect() -> Rect2:
    var icon_size = Vector2(CardIcon.ICON_WIDTH, CardIcon.ICON_HEIGHT)
    var upper_left = -0.5 * icon_size
    var size = icon_size * Vector2(len(icons), 1)
    if alignment == "Right":
        upper_left.x -= CardIcon.ICON_WIDTH * (len(icons) - 1)
    return Rect2(position + upper_left, size)
