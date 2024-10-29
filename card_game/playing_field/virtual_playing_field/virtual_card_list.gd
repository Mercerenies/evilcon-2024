extends Node

# Behaves like both Deck and CardStrip, since the two are identical
# from the perspective of a virtual playing engine.

signal cards_modified


func cards():
    return $CardContainer


func _on_card_container_cards_modified():
    # Propagate
    cards_modified.emit()
