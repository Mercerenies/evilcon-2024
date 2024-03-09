extends Node2D

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")

signal mouse_entered
signal mouse_exited

var card_type: CardType = null:
    set(v):
        card_type = v
        _update_display()


func _update_display() -> void:
    $TitleLabel.text = card_type.get_title()
    $TextLabel.text = card_type.get_text()
    $TextLabel.add_theme_font_override("font", card_type.get_text_font())
    $ArchetypesRow.icons = card_type.get_icon_row()
    $CostRow.icons = Util.filled_array(CardIcon.Frame.EVIL_STAR, card_type.get_star_cost())
    $CardPicture.frame = card_type.get_picture_index()
    $CardIcon.frame = Rarity.to_icon_index(card_type.get_rarity())
    $CardFrame.frame = Rarity.to_frame_index(card_type.get_rarity())
    $StatsLabel.text = card_type.get_stats_text()
    $IdLabel.text = "(Unique ID: %s)" % card_type.get_id()

    var archetypes_rect = $ArchetypesRow.get_rect()
    $ArchetypesTextLabel.position.x = archetypes_rect.end.x
    $ArchetypesTextLabel.text = card_type.get_archetypes_row_text()


func set_card(card):
    if card is Card:
        card_type = card.card_type
    else:
        card_type = card
    _update_display()


func on_added_to_strip(_strip) -> void:
    # No-op, no reaction to being added to strip.
    pass


func on_added_to_row(_row) -> void:
    # No-op, no reaction to being added to row.
    pass


func _on_card_frame_mouse_entered():
    # Propagate
    mouse_entered.emit()


func _on_card_frame_mouse_exited():
    # Propagate
    mouse_exited.emit()
