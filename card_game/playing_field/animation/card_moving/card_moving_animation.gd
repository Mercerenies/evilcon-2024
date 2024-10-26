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


# Performs the card moving animation. Awaits the completion of the
# animation.
#
# Accepted optional arguments:
#
# * start_angle (float) - Defaults to 0. This is the starting
#   angle of the playing card in the animation, in radians. All
#   angles are relative to the angle of the CardMovingAnimation.
#
# * end_angle (float) - Defaults to 0. This is the ending
#   angle of the playing card in the animation, in radians.
#   All angles are relative to the angle of the
#   CardMovingAnimation.
func animate(source: Vector2, destination: Vector2, opts = {}) -> void:
    var tween = create_tween()
    tween.set_parallel()

    self.position = source
    tween.tween_property(self, "position", destination, animation_time)

    var start_angle = Util.normalize_angle(opts.get("start_angle", 0.0))
    var end_angle = Util.normalize_angle(opts.get("end_angle", 0.0))
    _displayed_card.rotation = start_angle
    tween.tween_property(_displayed_card, "rotation", end_angle, animation_time)

    tween.play()
    await tween.finished


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        # Suppress mouse click events while animation is playing
        get_viewport().set_input_as_handled()
