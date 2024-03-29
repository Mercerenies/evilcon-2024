extends Node2D

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")

signal mouse_entered
signal mouse_exited

@export var overlay_rotates_with_node := false
@export var overlay_scales_with_node := false

# Do NOT re-assign these variables directly. These should only be
# modified through set_card.
var card_type: CardType = null
var card: Card = null

var overlay_text := "":
    set(v):
        overlay_text = v
        $OverlayTextNode/Label.text = v
        $OverlayTextNode.visible = (v != "")


var overlay_icons: Array = []:
    set(v):
        overlay_icons = v
        $OverlayIconRow.icons = v
        $OverlayIconRow.visible = (len(v) > 0)


func _process(_delta: float) -> void:
    if not overlay_rotates_with_node:
        $OverlayTextNode.global_rotation = 0
        $OverlayIconRow.global_rotation = 0
    if not overlay_scales_with_node:
        $OverlayTextNode.global_scale = Vector2.ONE
        $OverlayIconRow.global_scale = Vector2.ONE


func _update_display() -> void:
    $Card/TitleLabel.text = card_type.get_title()
    $Card/TextLabel.text = BBCodeModifier.process_bbcode(card_type.get_text())
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
        self.card_type = card.card_type
        self.card = card
    else:
        self.card_type = card
        self.card = null
    _update_display()


func play_highlight_animation() -> void:
    $AnimationPlayer.play(&"HighlightAnimation")
    while true:
        var anim = await $AnimationPlayer.animation_finished
        if anim == &"HighlightAnimation":
            break


func play_fade_in_animation() -> void:
    $AnimationPlayer.play(&"FadeInAnimation")
    while true:
        var anim = await $AnimationPlayer.animation_finished
        if anim == &"FadeInAnimation":
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
