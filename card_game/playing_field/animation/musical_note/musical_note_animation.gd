extends Node2D

signal main_animation_completed


# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimationPlayer.play("MusicalNoteAnimation")


func _on_animation_player_animation_finished(_anim_name):
    queue_free()


func emit_continue_signal():
    main_animation_completed.emit()
