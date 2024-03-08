extends Node2D


# Array of CardType; the last element is the top
var _cards: Array = []


func get_cards() -> Array:
    return _cards.duplicate()


func set_cards(arr: Array) -> void:
    _cards = arr.duplicate()
    _update_display()


func pop_card() -> 


func _update_display() -> void:
    var card_count = len(_cards)
    if card_count == 0:
        $Sprite2D.frame = 0
    elif card_count < 3:
        $Sprite2D.frame = 1
    elif card_count < 6:
        $Sprite2D.frame = 2
    else:
        $Sprite2D.frame = 3
