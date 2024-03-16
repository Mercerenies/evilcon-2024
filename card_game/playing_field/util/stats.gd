class_name Stats
extends Node

# Helpers for modifying stats, with accompanying animations. These
# functions can be awaited and will yield when the animation is
# completely played out, but it usually makes more sense to
# fire-and-forget them. All semantic changes to the game state are
# instantaneous, and only the animation is awaitable.

const NumberAnimation = preload("res://card_game/playing_field/animation/number_animation.tscn")

# No semantic change to stats, just the animation. This function can
# be called directly, but it usually makes more sense to call one of
# the other helpers, which also performs the semantic change.
static func play_animation_for_stat_change(playing_field, stat_node: Node2D, delta: int) -> void:
    var animation_layer = playing_field.get_animation_layer()
    var animation = NumberAnimation.instantiate()
    animation.position = animation_layer.to_local(stat_node.global_position)
    animation.amount = delta
    animation_layer.add_child(animation)
    await animation.animation_finished


static func set_evil_points(playing_field, player: StringName, new_value: int) -> void:
    var stats = playing_field.get_stats(player)
    var old_value = stats.evil_points
    stats.evil_points = new_value
    await play_animation_for_stat_change(playing_field, stats.get_evil_points_node(), new_value - old_value)


static func add_evil_points(playing_field, player: StringName, delta: int) -> void:
    var stats = playing_field.get_stats(player)
    await set_evil_points(playing_field, player, stats.evil_points + delta)


static func set_fort_defense(playing_field, player: StringName, new_value: int) -> void:
    var stats = playing_field.get_stats(player)
    var old_value = stats.fort_defense
    stats.fort_defense = new_value
    await play_animation_for_stat_change(playing_field, stats.get_fort_defense_node(), new_value - old_value)


static func add_fort_defense(playing_field, player: StringName, delta: int) -> void:
    var stats = playing_field.get_stats(player)
    await set_fort_defense(playing_field, player, stats.fort_defense + delta)


static func set_destiny_song(playing_field, player: StringName, new_value: int) -> void:
    var stats = playing_field.get_stats(player)
    var old_value = stats.destiny_song
    stats.destiny_song = new_value
    await play_animation_for_stat_change(playing_field, stats.get_destiny_song_node(), new_value - old_value)


static func add_destiny_song(playing_field, player: StringName, delta: int) -> void:
    var stats = playing_field.get_stats(player)
    await set_destiny_song(playing_field, player, stats.destiny_song + delta)
