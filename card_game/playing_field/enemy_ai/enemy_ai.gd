class_name EnemyAI
extends Node

# Base class for all Enemy AI nodes. The enemy AI is a Node in the
# scene tree which gets queried by the PlayingField whenever the
# player's opponent needs to perform an action. EnemyAI nodes also
# consume all user input by default while it is the enemy's turn,
# since the player should not be interacting with cards while the
# enemy is acting.

var is_enemy_turn := false

func on_enemy_turn_start(_playing_field) -> void:
    push_warning("Forgot to override on_enemy_turn_start!")


func start_enemy_turn(playing_field) -> void:
    # Called by the PlayingField to signal the start of the enemy's
    # turn. Should NOT be overridden in subclasses. Override
    # on_enemy_turn_start instead.
    is_enemy_turn = true
    on_enemy_turn_start(playing_field)


func end_enemy_turn(playing_field) -> void:
    # Called by the EnemyAI subclass to signal the end of the enemy's
    # turn. Should NOT be overridden in subclasses.
    is_enemy_turn = false
    playing_field.end_enemy_turn()


func _input(event: InputEvent) -> void:
    if is_enemy_turn:
        if event is InputEventMouseButton:
            get_viewport().set_input_as_handled()
