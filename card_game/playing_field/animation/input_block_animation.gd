extends Node2D

# Simple node that just blocks input. Used as a placeholder
# when an animation is playing somewhere other than
# AnimationLayer.

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        # Suppress mouse click events while animation is playing
        get_viewport().set_input_as_handled()
