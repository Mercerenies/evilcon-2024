extends Node2D

# TODO Make deck clickable, like the discard pile is

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
