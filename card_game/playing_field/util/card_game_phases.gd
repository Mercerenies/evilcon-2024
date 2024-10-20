class_name CardGamePhases
extends Node

# Helpers to evaluate different phases of the card game.

static func start_of_full_turn(playing_field) -> void:
    playing_field.turn_number += 1


static func draw_phase(playing_field, player: StringName) -> void:
    var evil_points_to_gain = StatsCalculator.get_evil_points_per_turn(playing_field, player)
    await Stats.add_evil_points(playing_field, player, evil_points_to_gain)

    var cards_to_draw = StatsCalculator.get_cards_per_turn(playing_field, player)
    await CardGameApi.draw_cards(playing_field, player, cards_to_draw)

    await CardGameApi.broadcast_to_cards_async(playing_field, "on_draw_phase")


static func attack_phase(playing_field, _player: StringName) -> void:
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_attack_phase")


static func morale_phase(playing_field, _player: StringName) -> void:
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_morale_phase")


static func standby_phase(playing_field, _player: StringName) -> void:
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_standby_phase")


static func end_phase(playing_field, player: StringName) -> void:
    await Stats.set_evil_points(playing_field, player, 0)

    await CardGameApi.broadcast_to_cards_async(playing_field, "on_end_phase")


static func end_of_full_turn(_playing_field) -> void:
    # TODO This one might actually do nothing, but it makes sense to
    # have it here for the sake of completeness. Consider whether we
    # want to add anything to this method.
    pass
