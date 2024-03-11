extends "res://card_game/playing_field/deck/deck.gd"

const PlayingCardDisplay = preload("res://card_game/playing_card/playing_card_display/playing_card_display.tscn")

signal pile_clicked

var _mouse_over = false

func update_display() -> void:
    super.update_display()
    if has_node("DisplayNode/TopCard"):
        $DisplayNode/TopCard.free()
    if cards().card_count() > 0:
        var node = PlayingCardDisplay.instantiate()
        node.name = "TopCard"
        node.scale = Vector2(0.25, 0.25)
        node.set_card(cards().peek_card())
        match get_sprite().frame:
            0, 1:
                node.position = Vector2(0, 2)
            2:
                node.position = Vector2(0, -2)
            _:
                node.position = Vector2(0, -5)
        $DisplayNode.add_child(node)


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
