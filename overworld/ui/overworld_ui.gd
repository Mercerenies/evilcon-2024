extends CanvasLayer

@export var active_room: Node


func get_player() -> Node:
    return active_room.player_character


func _physics_process(_delta: float) -> void:
    var player = get_player()
    if player != null:
        var primary_button_action = player.get_primary_button_action()
        match primary_button_action:
            Constants.PrimaryButtonAction.JUMP:
                $ActionIconPanel.set_space_action_frame(0)
            Constants.PrimaryButtonAction.TALK:
                $ActionIconPanel.set_space_action_frame(1)
