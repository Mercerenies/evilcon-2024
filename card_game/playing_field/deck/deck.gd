extends Node2D

signal pile_clicked

var _mouse_over = false

## Whether or not the deck sprite should use the second
## row of images, intended to be shown upside-down.
@export var flipped := false

@export var overlay_rotates_with_node := false
@export var overlay_scales_with_node := false

func update_display() -> void:
    var card_count = $CardContainer.card_count()
    if card_count == 0:
        $DisplayNode/DeckSprite.frame = 0
    elif card_count < 3:
        $DisplayNode/DeckSprite.frame = 1
    elif card_count < 6:
        $DisplayNode/DeckSprite.frame = 2
    else:
        $DisplayNode/DeckSprite.frame = 3
    if flipped:
        $DisplayNode/DeckSprite.frame += 4
    %QuantityLabel.text = str(card_count)


func get_sprite() -> Sprite2D:
    return $DisplayNode/DeckSprite


func _ready():
    update_display()


func _process(_delta: float):
    if not overlay_rotates_with_node:
        $QuantityLabelNode2D.global_rotation = 0
    if not overlay_scales_with_node:
        $QuantityLabelNode2D.global_scale = Vector2.ONE


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
