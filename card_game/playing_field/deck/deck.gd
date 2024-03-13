extends Node2D

signal pile_clicked

var _mouse_over = false

func update_display() -> void:
    var card_count = $CardContainer.card_count()
    if card_count == 0:
        $DisplayNode/Sprite2D.frame = 0
    elif card_count < 3:
        $DisplayNode/Sprite2D.frame = 1
    elif card_count < 6:
        $DisplayNode/Sprite2D.frame = 2
    else:
        $DisplayNode/Sprite2D.frame = 3
    $QuantityLabel.text = str(card_count)


func get_sprite() -> Sprite2D:
    return $DisplayNode/Sprite2D


func _ready():
    update_display()


func _on_card_container_cards_modified():
    update_display()


func cards():
    return $CardContainer


func _on_area_2d_mouse_entered():
    _mouse_over = true
    $DisplayNode.scale = Vector2.ONE * 1.2


func _on_area_2d_mouse_exited():
    _mouse_over = false
    $DisplayNode.scale = Vector2.ONE


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if _mouse_over:
                pile_clicked.emit()
                get_viewport().set_input_as_handled()
