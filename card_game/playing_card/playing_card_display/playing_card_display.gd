extends Node2D

var card_type: CardType = null:
    set(v):
        card_type = v
        _update_display()


func _update_display() -> void:
    $TitleLabel.text = card_type.get_title()
    $TextLabel.text = card_type.get_text()
    $TextLabel.add_theme_font_override("font", card_type.get_text_font())
