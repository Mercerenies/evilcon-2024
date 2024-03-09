@tool
extends Node2D

signal card_added(card_node)

# TODO Does not currently scroll


@export var width: float = 1024:
    set(w):
        width = w
        _update_rect()
@export var margin_above: float = 32:
    set(m):
        margin_above = m
        _update_rect()
        _update_cards()
@export var margin_below: float = 32:
    set(m):
        margin_below = m
        _update_rect()
        _update_cards()
@export var margin_horizontal: float = 16:
    set(m):
        margin_horizontal = m
        _update_cards()

# The scene to display for each card. The root node of the scene must
# have the following.
#
# * set_card(card) takes a Card or CardType (compatible with the type
#   of the CardStrip scene)
#
# * on_added_to_row(row) takes the ScrollableCardRow and can respond
#   to the event of being added to it
@export var card_display_scene: PackedScene


func get_rect() -> Rect2:
    return Rect2(0, - margin_above - Constants.CARD_SIZE.y / 2, width, margin_above + Constants.CARD_SIZE.y + margin_below)


func cards():
    return $CardContainer


func _update_rect() -> void:
    var node = $VisualRect
    var rect = get_rect()
    node.polygon = PackedVector2Array([
        Vector2(rect.position.x, rect.position.y),
        Vector2(rect.position.x, rect.end     .y),
        Vector2(rect.end     .x, rect.end     .y),
        Vector2(rect.end     .x, rect.position.y),
    ])


func _update_cards() -> void:
    Util.free_all_children($AllCards)
    var cards_array = $CardContainer.card_array()
    var card_distance = margin_horizontal * 2 + Constants.CARD_SIZE.x

    var pos = Vector2(width / 2, 0)
    for card in cards_array:
        var card_node = card_display_scene.instantiate()
        card_node.position = pos
        card_node.set_card(card)
        $AllCards.add_child(card_node)
        card_node.on_added_to_row(self)
        card_added.emit(card_node)
        pos.x += card_distance


func _on_card_container_cards_modified():
    _update_cards()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        queue_free()
        get_viewport().set_input_as_handled()
