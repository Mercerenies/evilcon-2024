extends "res://card_game/playing_card/playing_card_display/playing_card_display.gd"

signal card_clicked


var _mouse_overlapping = false
var _owning_strip = null

@onready var base_scale = scale


func on_added_to_strip(strip) -> void:
    _owning_strip = strip


func _on_mouse_entered():
    _mouse_overlapping = true


func _on_mouse_exited():
    _mouse_overlapping = false


func _is_highlighted(global_mouse_position: Vector2) -> bool:
    if not _mouse_overlapping:
        return false
    if _owning_strip == null:
        return false
    var local_mouse_position = _owning_strip.to_local(global_mouse_position)
    return _owning_strip.nearest_card_node_to(local_mouse_position) == self


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if _is_highlighted(event.position):
            scale = base_scale * 1.2
            z_index = 1
        else:
            scale = base_scale
            z_index = 0
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if _is_highlighted(event.position):
                card_clicked.emit()
                get_viewport().set_input_as_handled()
