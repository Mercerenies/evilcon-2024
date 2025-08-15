@tool

extends Sprite3D

enum FrameMode {
    ## A 4x1 image containing the four directions RIGHT, DOWN, LEFT,
    ## UP in order. No walking animations.
    STATIC_FOUR,
    ## Full 8x4 image. Each row is a direction, starting at RIGHT and
    ## going clockwise.
    ##
    ## Within each row, the four frames consist of a walking
    ## animation. The first frame of each row. shall be appropriate
    ## for idling.
    FULL_MOBILITY,
}

## Frame mode, determines the size and flexibility of the character's
## sprite.
@export var frame_mode: FrameMode = FrameMode.FULL_MOBILITY:
    set(v):
        frame_mode = v
        _update_frames_count()


func _update_frames_count() -> void:
    match frame_mode:
        FrameMode.STATIC_FOUR:
            self.hframes = 4
            self.vframes = 1
        FrameMode.FULL_MOBILITY:
            self.hframes = 4
            self.vframes = 8


func update_frame(facing_dir: int, animation_tick: float) -> void:
    var normalized_animation_tick = (int(animation_tick) % 4 + 4) % 4
    match frame_mode:
        FrameMode.STATIC_FOUR:
            self.frame = _undiagonalize(facing_dir)
        FrameMode.FULL_MOBILITY:
            self.frame = facing_dir * 4 + normalized_animation_tick


func _undiagonalize(facing_dir: int) -> int:
    match facing_dir:
        0:
            return 0
        1, 2, 3:
            return 1
        4:
            return 2
        5, 6, 7:
            return 3
        _:
            push_warning("Invalid direction %d" % facing_dir)
            return 0
