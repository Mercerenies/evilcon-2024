extends Node2D

func _update_display() -> void:
    var card_count = $CardContainer.card_count()
    if card_count == 0:
        $Sprite2D.frame = 0
    elif card_count < 3:
        $Sprite2D.frame = 1
    elif card_count < 6:
        $Sprite2D.frame = 2
    else:
        $Sprite2D.frame = 3
    $QuantityLabel.text = str(card_count)


func _ready():
    _update_display()


func _on_card_container_cards_modified():
    _update_display()


func cards():
    return $CardContainer
