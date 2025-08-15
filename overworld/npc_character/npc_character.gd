@tool

extends AnimatableBody3D

const FaceableSprite3D = preload("res://overworld/faceable_sprite_3d/faceable_sprite_3d.gd")


@export var texture: Texture:
    get():
        return $FaceableSprite3D.texture
    set(v):
        if not is_inside_tree():
            await ready
        $FaceableSprite3D.texture = v


@export var frame_mode: FaceableSprite3D.FrameMode:
    get():
        return $FaceableSprite3D.frame_mode
    set(v):
        if not is_inside_tree():
            await ready
        $FaceableSprite3D.frame_mode = v


@export_enum("Right", "Down-Right", "Down", "Down-Left", "Left", "Up-Left", "Up", "Up-Right") var facing_direction: int = 2:
    set(v):
        if not is_inside_tree():
            await ready
        facing_direction = v
        $FaceableSprite3D.update_frame(v, 0.0)


func _ready() -> void:
    $FaceableSprite3D.update_frame(facing_direction, 0.0)
