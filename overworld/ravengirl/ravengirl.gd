extends Node3D

const MAX_MOVE_SPEED := 1.8  # meters per second
const MOVE_MIN_ACCELERATION := 7.0  # meters per second^2
const MOVE_MAX_ACCELERATION := 10.0  # meters per second^2
const MOVE_FRICTION := 8.0  # meters per second^2
const ANIMATION_SPEED := 9.1 # frames per second

var _move_velocity := Vector3.ZERO
var _animation_tick := 0.0

func _physics_process(delta: float) -> void:
    var input_dir = _get_input_move_dir()

    if input_dir != -1:
        var input_vec = Vector3.RIGHT.rotated(Vector3.DOWN, input_dir * PI / 4.0)
        var accel_lerp = (_move_velocity.length() / MAX_MOVE_SPEED) ** 6
        var accel = lerp(MOVE_MAX_ACCELERATION, MOVE_MIN_ACCELERATION, accel_lerp)
        accel = lerp(accel, MOVE_MAX_ACCELERATION, 1.0 - _move_velocity.normalized().dot(input_vec))
        accel = clamp(accel, MOVE_MIN_ACCELERATION, MOVE_MAX_ACCELERATION)
        _move_velocity += input_vec * accel * delta
    else:
        if _move_velocity.length() < MOVE_FRICTION * delta:
            _move_velocity = Vector3.ZERO
        else:
            _move_velocity *= 1.0 - MOVE_FRICTION * delta / _move_velocity.length()

    if _move_velocity.length() > MAX_MOVE_SPEED:
        _move_velocity = _move_velocity.normalized() * MAX_MOVE_SPEED
        #_move_velocity *= 1.0 - MOVE_SPEED_CORRECTION_FRICTION * delta / _move_velocity.length()

    position += _move_velocity * delta

    # Player animation
    if input_dir == -1:
        _animation_tick = 0.0
    else:
        var anim_speed = ANIMATION_SPEED
        anim_speed *= (_move_velocity.length() / MAX_MOVE_SPEED)
        _animation_tick += delta * anim_speed
        $Sprite3D.frame = (input_dir * 4 + int(_animation_tick) % 4)


# Returns unit vector of player 8-directional input direction, or
# Vector2.ZERO if no input is being pressed.
func _get_input_move_vec() -> Vector3:
    var dir = _get_input_move_dir()
    if dir == -1:
        return Vector3.ZERO
    else:
        return Vector3.RIGHT.rotated(Vector3.DOWN, dir * PI / 4.0)


# Returns direction (from 0 to 7 in clockwise order) of player
# 8-directional input direction, or -1 if no input is being pressed.
func _get_input_move_dir() -> int:
    var input_bitmask = 0
    input_bitmask |= 1 if Input.is_action_pressed("world_move_right") else 0
    input_bitmask |= 2 if Input.is_action_pressed("world_move_down") else 0
    input_bitmask |= 4 if Input.is_action_pressed("world_move_left") else 0
    input_bitmask |= 8 if Input.is_action_pressed("world_move_up") else 0
    if Util.bits_subset(9, input_bitmask):
        return 7
    elif Util.bits_subset(12, input_bitmask):
        return 5
    elif Util.bits_subset(6, input_bitmask):
        return 3
    elif Util.bits_subset(3, input_bitmask):
        return 1
    elif Util.bits_subset(1, input_bitmask):
        return 0
    elif Util.bits_subset(2, input_bitmask):
        return 2
    elif Util.bits_subset(4, input_bitmask):
        return 4
    elif Util.bits_subset(8, input_bitmask):
        return 6
    else:
        return -1
