extends Node3D

@export var target_node: Node3D

## Hides this node if the target (which must be a CharacterBody3D) is on
## the floor.
@export var hide_when_floored: bool = false


func _ready() -> void:
    $RayCast3D.add_exception(target_node)


func _physics_process(_delta: float) -> void:
    if $RayCast3D.is_colliding():
        $Sprite3D.visible = true
        $Sprite3D.position = to_local($RayCast3D.get_collision_point())
        $Sprite3D.position.y += 0.05  # Draw above the floor
    else:
        $Sprite3D.visible = false
        $Sprite3D.position = Vector3.ZERO

    if hide_when_floored and target_node.is_on_floor():
        $Sprite3D.visible = false
