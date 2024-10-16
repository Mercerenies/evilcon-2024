extends Node2D

@export var animation_time: float = 0.25

@onready var _displayed_card = $PlayingCardDisplay


func set_card(card) -> void:
    _displayed_card.set_card(card)


func replace_displayed_card(new_card_node: Node) -> void:
    _displayed_card.free()
    add_child(new_card_node)
    _displayed_card = new_card_node


func get_displayed_card() -> Node:
    return _displayed_card


func animate(source: Vector2, destination: Vector2) -> void:
    var tween = create_tween()
    self.position = source
    tween.tween_property(self, "position", destination, animation_time)
    tween.play()
    await tween.finished


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        # Suppress mouse click events while animation is playing
        get_viewport().set_input_as_handled()
