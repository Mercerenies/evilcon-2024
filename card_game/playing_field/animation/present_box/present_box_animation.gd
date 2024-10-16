extends Node2D

signal main_animation_completed


func set_card(card) -> void:
    %PlayingCardDisplay.set_card(card)


func _ready():
    $AnimationPlayer.play("PresentBoxAnimation")


func _on_animation_player_animation_finished(_anim_name):
    main_animation_completed.emit()
    queue_free()
