extends Node2D

signal animation_finished

const POSITIVE_COLOR := Color.DARK_GREEN
const NEGATIVE_COLOR := Color.DARK_RED

@export var speed: float = 15.0
var direction: Vector2 = Vector2.RIGHT

var amount: int = 0:
    set(v):
        amount = v
        _update_label()


var custom_label_text = null:
    set(v):
        custom_label_text = v
        _update_label()

var custom_label_color = null:
    set(v):
        custom_label_color = v
        _update_label()


func _ready() -> void:
    _update_label()
    $DecayAnimationPlayer.play(&"DecayAnimation")
    # Point roughly toward the center of the screen
    var viewport_rect = get_viewport().get_visible_rect()
    direction = (viewport_rect.get_center() - global_position).normalized()
    direction = direction.rotated(randf_range(- PI / 6, PI / 6))


func _process(delta: float) -> void:
    position += delta * speed * direction


func _update_label() -> void:
    if custom_label_text != null:
        $Label.text = custom_label_text
    else:
        $Label.text = "%+d" % amount
    var color
    if custom_label_color != null:
        color = custom_label_color
    else:
        color = POSITIVE_COLOR if amount >= 0 else NEGATIVE_COLOR
    $Label.add_theme_color_override(&"font_color", color)


func _on_decay_animation_player_animation_finished(_anim_name):
    animation_finished.emit()
    queue_free()
