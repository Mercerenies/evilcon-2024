extends Node2D

# A row of cards displayed in order.

@export_enum("Card", "CardType") var contained_type:
    get:
        return $CardContainer.contained_type
    set(v):
        $CardContainer.contained_type = v


func _on_card_container_cards_modified():
    pass # Replace with function body.
