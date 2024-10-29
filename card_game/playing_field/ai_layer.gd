extends Node


@export var playing_field: Node


func _input(event: InputEvent) -> void:
    var agent = playing_field.player_agent(playing_field.turn_player)
    if agent.suppresses_input():
        if event is InputEventMouseButton:
            get_viewport().set_input_as_handled()
