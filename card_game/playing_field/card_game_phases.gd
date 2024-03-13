class_name CardGamePhases
extends Node

# Helpers to evaluate different phases of the card game.

static func start_of_full_turn(playing_field) -> void:
    playing_field.turn_number += 1


static func draw_phase(playing_field, player: StringName) -> void:
    var stats = playing_field.get_stats(player)

    var evil_points_to_gain = StatsCalculator.get_evil_points_per_turn(playing_field, player)
    stats.evil_points = evil_points_to_gain
    CardGameApi.play_animation_for_stat_change(playing_field, stats.get_evil_points_node(), evil_points_to_gain)

    var cards_to_draw = StatsCalculator.get_cards_per_turn(playing_field, player)
    await CardGameApi.draw_cards(playing_field, player, cards_to_draw)


static func attack_phase(_playing_field, _player: StringName) -> void:
    # TODO
    pass


static func morale_phase(_playing_field, _player: StringName) -> void:
    # TODO
    pass


static func standby_phase(_playing_field, _player: StringName) -> void:
    # TODO
    pass


static func end_phase(_playing_field, _player: StringName) -> void:
    var stats = _playing_field.get_stats(_player)
    CardGameApi.play_animation_for_stat_change(_playing_field, stats.get_evil_points_node(), - stats.evil_points)
    stats.evil_points = 0


static func end_of_full_turn(_playing_field) -> void:
    # TODO This one might actually do nothing, but it makes sense to
    # have it here for the sake of completeness. Consider whether we
    # want to add anything to this method.
    pass
