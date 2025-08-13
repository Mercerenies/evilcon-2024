extends Node2D

const MAX_MOVE_SPEED := 180.0  # pixels per second
const MOVE_ACCELERATION := 700.0  # pixels per second^2
const MOVE_FRICTION := 800.0  # pixels per second^2
#const MOVE_SPEED_CORRECTION_FRICTION := 900.0  # pixels per second^2

var _move_velocity := Vector2.ZERO

func _process(delta: float) -> void:
    var input_dir = _get_input_move_dir()

    if input_dir != Vector2.ZERO:
        var accel = MOVE_ACCELERATION * delta
        if _move_velocity.length() < 40.0:
            accel *= 3
        _move_velocity += input_dir * accel
    else:
        if _move_velocity.length() < MOVE_FRICTION * delta:
            _move_velocity = Vector2.ZERO
        else:
            _move_velocity *= 1.0 - MOVE_FRICTION * delta / _move_velocity.length()

    if _move_velocity.length() > MAX_MOVE_SPEED:
        _move_velocity = _move_velocity.normalized() * MAX_MOVE_SPEED
        #_move_velocity *= 1.0 - MOVE_SPEED_CORRECTION_FRICTION * delta / _move_velocity.length()
    position += _move_velocity * delta
    print(_move_velocity.length())


# Returns unit vector of player 8-directional input direction, or
# Vector2.ZERO if no input is being pressed.
func _get_input_move_dir() -> Vector2:
    var input_bitmask = 0
    input_bitmask |= 1 if Input.is_action_pressed("world_move_right") else 0
    input_bitmask |= 2 if Input.is_action_pressed("world_move_down") else 0
    input_bitmask |= 4 if Input.is_action_pressed("world_move_left") else 0
    input_bitmask |= 8 if Input.is_action_pressed("world_move_up") else 0
    if Util.bits_subset(9, input_bitmask):
        return Vector2.RIGHT.rotated(- PI / 4)
    elif Util.bits_subset(12, input_bitmask):
        return Vector2.RIGHT.rotated(- 3 * PI / 4)
    elif Util.bits_subset(6, input_bitmask):
        return Vector2.RIGHT.rotated(3 * PI / 4)
    elif Util.bits_subset(3, input_bitmask):
        return Vector2.RIGHT.rotated(PI / 4)
    elif Util.bits_subset(1, input_bitmask):
        return Vector2.RIGHT
    elif Util.bits_subset(2, input_bitmask):
        return Vector2.DOWN
    elif Util.bits_subset(4, input_bitmask):
        return Vector2.LEFT
    elif Util.bits_subset(8, input_bitmask):
        return Vector2.UP
    else:
        return Vector2.ZERO
