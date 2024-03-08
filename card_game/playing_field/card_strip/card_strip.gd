@tool
extends Node2D

# A row of cards displayed in order.

# The scene to display for each card. The root node of the scene must
# have a set_card(card) method which takes either a Card or a CardType
# (compatible with the type of the CardStrip scene)
@export var card_display_scene: PackedScene

@export var maximum_card_distance: float = Constants.CARD_SIZE.x + 128
@export var total_width: float = 2000:
    set(w):
        total_width = w
        _update_debug_rect()


func _ready() -> void:
    if not Engine.is_editor_hint():
        $DebugVisualRect.free()


func cards():
    return $CardContainer


func _on_card_container_cards_modified():
    Util.free_all_children($AllCards)
    var cards_array = $CardContainer.card_array()
    var card_distance = min((total_width - Constants.CARD_SIZE.x) / max(len(cards_array) - 1, 1), maximum_card_distance)
    var total_distance = card_distance * max(len(cards_array) - 1, 0)
    var pos = Vector2(- total_distance / 2, 0)
    for card in cards_array:
        var card_node = card_display_scene.instantiate()
        card_node.position = pos
        card_node.set_card(card)
        $AllCards.add_child(card_node)
        pos.x += card_distance


func _update_debug_rect() -> void:
    # The node $DebugVisualRect is just for the editor. It has
    # no purpose at runtime but is used at edit time to better
    # visualize the bounds of the CardStrip.
    var node = $DebugVisualRect
    node.polygon = PackedVector2Array([
        Vector2(- total_width / 2, - Constants.CARD_SIZE.y / 2),
        Vector2(  total_width / 2, - Constants.CARD_SIZE.y / 2),
        Vector2(  total_width / 2,   Constants.CARD_SIZE.y / 2),
        Vector2(- total_width / 2,   Constants.CARD_SIZE.y / 2),
    ])
