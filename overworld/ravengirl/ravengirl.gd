extends CharacterBody3D

const MAX_MOVE_SPEED := 1.8  # meters per second
const MOVE_MIN_ACCELERATION := 7.0  # meters per second^2
const MOVE_MAX_ACCELERATION := 10.0  # meters per second^2
const MOVE_FRICTION := 8.0  # meters per second^2
const ANIMATION_SPEED := 9.1  # frames per second

const BASE_GRAVITY = -60.0  # meters per second^2
const TERMINAL_VELOCITY := 20.0  # meters per second
const JUMP_IMPULSE := 14.0  # meters per second
const DASH_IMPULSE := 5.5  # meters per second
const DASH_MAX_SPEED := 5.5  # meters per second

var _animation_tick := 0.2
var _last_input_dir := 2

@export var dash_max_speed_lerp := 0.0
@export var is_dashing := false

func _physics_process(delta: float) -> void:
    _update_horizontal_movement_dir(delta)
    _handle_jumping()
    _handle_dashing()

    # Gravity
    velocity.y += BASE_GRAVITY * delta
    if abs(velocity.y) > TERMINAL_VELOCITY:
        velocity.y = sign(velocity.y) * TERMINAL_VELOCITY

    move_and_slide()

    # Player animation
    var xz_velocity = velocity.slide(Vector3.UP)
    var input_dir = _get_input_move_dir()
    if is_dashing:
        # Dashing
        _animation_tick = 1.5
    if not is_on_floor():
        # Airborne
        _animation_tick = 1.5
    elif input_dir == -1:
        _animation_tick = 0.8
    else:
        _last_input_dir = input_dir
        var anim_speed = ANIMATION_SPEED
        anim_speed *= (xz_velocity.length() / MAX_MOVE_SPEED)
        _animation_tick += delta * anim_speed
    $Sprite3D.frame = (_last_input_dir * 4 + int(_animation_tick) % 4)


func _update_horizontal_movement_dir(delta: float) -> void:
    var input_dir = _get_input_move_dir()
    var xz_velocity = velocity.slide(Vector3.UP)
    if input_dir != -1:
        var input_vec = Vector3.RIGHT.rotated(Vector3.DOWN, input_dir * PI / 4.0)
        var accel_lerp = (velocity.length() / MAX_MOVE_SPEED) ** 6
        var accel = lerp(MOVE_MAX_ACCELERATION, MOVE_MIN_ACCELERATION, accel_lerp)
        accel = lerp(accel, MOVE_MAX_ACCELERATION, 1.0 - velocity.normalized().dot(input_vec))
        accel = clamp(accel, MOVE_MIN_ACCELERATION, MOVE_MAX_ACCELERATION)
        if not is_on_floor():
            accel /= 3.0
        velocity += input_vec * accel * delta
    elif is_on_floor():
        if xz_velocity.length() < MOVE_FRICTION * delta:
            velocity.x = 0.0
            velocity.z = 0.0
        else:
            velocity.x *= 1.0 - MOVE_FRICTION * delta / xz_velocity.length()
            velocity.z *= 1.0 - MOVE_FRICTION * delta / xz_velocity.length()

    xz_velocity = velocity.slide(Vector3.UP)
    var speed_cap = MAX_MOVE_SPEED
    if is_dashing:
        speed_cap = lerp(MAX_MOVE_SPEED, DASH_MAX_SPEED, dash_max_speed_lerp)
    if xz_velocity.length() > speed_cap:
        velocity.x = xz_velocity.normalized().x * speed_cap
        velocity.z = xz_velocity.normalized().z * speed_cap


func _handle_jumping() -> void:
    if Input.is_action_just_pressed("world_move_jump") and is_on_floor():
        velocity.y = JUMP_IMPULSE


func _handle_dashing() -> void:
    if not (is_on_floor() and $DashCooldownTimer.is_stopped() and Input.is_action_just_pressed("world_move_dash")):
        return
    var input_dir = _get_input_move_dir()
    if input_dir == -1:
        return

    var input_vec = Vector3.RIGHT.rotated(Vector3.DOWN, input_dir * PI / 4.0)
    velocity.x += DASH_IMPULSE * input_vec.x
    velocity.z += DASH_IMPULSE * input_vec.z
    $AnimationPlayer.play("dash")
    $DashCooldownTimer.start()


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
