extends "res://card_game/playing_field/deck/deck.gd"

const PlayingCardDisplay = preload("res://card_game/playing_card/playing_card_display/playing_card_display.tscn")

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
            3:
                node.position = Vector2(0, -5)
            4, 5:
                node.position = Vector2(0, -2)
            6:
                node.position = Vector2(0, 2)
            7:
                node.position = Vector2(0, 5)
        $DisplayNode.add_child(node)
