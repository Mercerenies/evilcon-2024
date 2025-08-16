extends Node3D


@export var owner_node: Node

@onready var _raycasts = (
    [$CenterRayCast, $LeftRayCast, $RightRayCast]
)


func _ready() -> void:
    if owner_node != null:
        for raycast in _raycasts:
            raycast.add_exception(owner_node)


func get_collider():
    for raycast in _raycasts:
        if raycast.is_colliding():
            return raycast.get_collider()
    return null
