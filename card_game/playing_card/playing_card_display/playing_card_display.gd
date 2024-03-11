extends Node2D

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")

signal mouse_entered
signal mouse_exited

var card_type: CardType = null:
    set(v):
        card_type = v
        _update_display()


func _update_display() -> void:
    $Card/TitleLabel.text = card_type.get_title()
    $Card/TextLabel.text = card_type.get_text()
    $Card/TextLabel.add_theme_font_override("font", card_type.get_text_font())
    $Card/ArchetypesRow.icons = card_type.get_icon_row()
    $Card/CostRow.icons = Util.filled_array(CardIcon.Frame.EVIL_STAR, card_type.get_star_cost())
    $Card/CardPicture.frame = card_type.get_picture_index()
    $Card/CardIcon.frame = Rarity.to_icon_index(card_type.get_rarity())
    $Card/CardFrame.frame = Rarity.to_frame_index(card_type.get_rarity())
    $Card/StatsLabel.text = card_type.get_stats_text()
    $Card/IdLabel.text = "(Unique ID: %s)" % card_type.get_id()

    var archetypes_rect = $Card/ArchetypesRow.get_rect()
    $Card/ArchetypesTextLabel.position.x = archetypes_rect.end.x
    $Card/ArchetypesTextLabel.text = card_type.get_archetypes_row_text()


func set_card(card):
    if card is Card:
        card_type = card.card_type
    else:
        card_type = card
    _update_display()


func play_highlight_animation() -> void:
    $AnimationPlayer.play(&"HighlightAnimation")
    while true:
        var anim = $AnimationPlayer.animation_finished.await()
        if anim == &"HighlightAnimation":
            break


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
