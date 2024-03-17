@tool
extends Node2D

signal card_added(card_node)


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

# Monitoring clicks to distinguish them from drag gestures
var _click_timer := 0.0
var _click_pos := Vector2.ZERO
var _dragging := false
var _drag_pos := Vector2.ZERO


func _ready() -> void:
    $AllCards.position = Vector2(width / 2, 0)


func _process(delta: float) -> void:
    _click_timer -= delta


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
    $ButtonsRow.position.x = rect.position.x + rect.size.x / 2
    $ButtonsRow.position.y = rect.end.y - margin_below / 2


func _update_cards() -> void:
    if Engine.is_editor_hint():
        return
    Util.queue_free_all_children($AllCards)
    var cards_array = $CardContainer.card_array()
    var card_distance = margin_horizontal * 2 + Constants.CARD_SIZE.x

    var pos = Vector2(0, 0)
    for card in cards_array:
        var card_node = card_display_scene.instantiate()
        card_node.position = pos
        card_node.set_card(card)
        $AllCards.add_child(card_node)
        card_node.on_added_to_row(self)
        card_added.emit(card_node)
        pos.x += card_distance


func _min_all_cards_x() -> float:
    var card_distance = margin_horizontal * 2 + Constants.CARD_SIZE.x
    return _max_all_cards_x() - card_distance * ($CardContainer.card_count() - 1)


func _max_all_cards_x() -> float:
    return width / 2


# amount = 0 is the far left, amount = 1 is the far right
func set_scroll_position(amount: float) -> void:
    $AllCards.position.x = lerp(_max_all_cards_x(), _min_all_cards_x(), amount)


func clear_buttons() -> void:
    Util.queue_free_all_children($ButtonsRow/HBoxContainer)


func append_button(button: Button) -> void:
    var container = $ButtonsRow/HBoxContainer
    container.add_child(button)


func _on_card_container_cards_modified():
    _update_cards()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _click_timer = 0.5
        _click_pos = event.position
        _maybe_start_dragging(event)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and not event.pressed:
        if _click_timer > 0.0 and _click_pos.distance_squared_to(event.position) < 64.0:
            queue_free()
            get_viewport().set_input_as_handled()
        _click_timer = 0.0
        _dragging = false
    elif event is InputEventMouseMotion:
        if _dragging:
            var mouse_pos = to_local(event.position)
            $AllCards.position.x = mouse_pos.x - _drag_pos.x
            $AllCards.position.x = clamp($AllCards.position.x, _min_all_cards_x(), _max_all_cards_x())
            get_viewport().set_input_as_handled()


func _maybe_start_dragging(event: InputEventMouseButton) -> void:
    var rect = get_rect()
    if rect.has_point(to_local(event.position)):
        _dragging = true
        _drag_pos = $AllCards.to_local(event.position)
