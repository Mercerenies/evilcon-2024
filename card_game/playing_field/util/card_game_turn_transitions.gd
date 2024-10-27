class_name CardGameTurnTransitions
extends Node

# Helpers to begin the game and transition between player turns.

# Initial deal of five cards per hand, should be run once at the very
# beginning of an instance of the card game, usually from
# PlayingField.begin_game().
static func begin_game(playing_field) -> void:
    await draw_initial_hand(playing_field, CardPlayer.BOTTOM)
    await draw_initial_hand(playing_field, CardPlayer.TOP)


static func draw_initial_hand(playing_field, player: StringName) -> void:
    var hand_limit = StatsCalculator.get_hand_limit(playing_field, player)
    await CardGameApi.draw_cards(playing_field, player, hand_limit)


static func begin_turn(playing_field, player: StringName) -> void:
    playing_field.turn_player = player
    await CardGamePhases.draw_phase(playing_field, player)
    await CardGamePhases.attack_phase(playing_field, player)
    await CardGamePhases.morale_phase(playing_field, player)
    await CardGamePhases.standby_phase(playing_field, player)


static func end_turn(playing_field, player: StringName) -> void:
    await CardGamePhases.end_phase(playing_field, player)
