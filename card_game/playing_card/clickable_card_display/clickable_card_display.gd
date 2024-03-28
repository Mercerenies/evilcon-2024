extends "res://card_game/playing_card/playing_card_display/playing_card_display.gd"

signal card_clicked
signal card_right_clicked


var _mouse_overlapping = false
var _owning_strip = null


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
            $Card.scale = Vector2.ONE * 1.2
            z_index = 1
        else:
            $Card.scale = Vector2.ONE
            z_index = 0
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if _is_highlighted(event.position):
                card_clicked.emit()
                get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            if _is_highlighted(event.position):
                card_right_clicked.emit()
                get_viewport().set_input_as_handled()
