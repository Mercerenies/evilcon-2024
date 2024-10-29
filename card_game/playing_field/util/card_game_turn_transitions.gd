class_name CardGameTurnTransitions
extends Node

# Helpers to begin the game and transition between player turns.

# Plays the whole game, from start to finish, and awaits until the game is completed. Returns the winner.
static func play_full_game(playing_field) -> StringName:
    # By setting up a promise (rather than just blindly awaiting the
    # game_ended signal), we can deal with the corner case where the
    # game ends instantaneously without any user input.
    var winner_promise = Promise.new()
    playing_field.game_ended.connect(winner_promise.resolve_with_data)

    # Fire and forget the game loop
    _run_game_loop(playing_field)

    var winner = await winner_promise.async_awaiter()
    return winner


static func _run_game_loop(playing_field) -> void:
    await begin_game(playing_field)
    while true:
        await CardGamePhases.start_of_full_turn(playing_field)
        await _run_turn_for(playing_field, CardPlayer.BOTTOM)
        await _run_turn_for(playing_field, CardPlayer.TOP)
        await CardGamePhases.end_of_full_turn(playing_field)


# Assuming the playing field is currently in the middle of a game,
# continues from the current point in the game, up until the endgame.
static func play_rest_of_game(playing_field) -> StringName:
    # By setting up a promise (rather than just blindly awaiting the
    # game_ended signal), we can deal with the corner case where the
    # game ends instantaneously without any user input.
    var winner_promise = Promise.new()
    playing_field.game_ended.connect(winner_promise.resolve_with_data)

    # Fire and forget the game loop
    _run_rest_of_game_loop(playing_field)

    var winner = await winner_promise.async_awaiter()
    return winner


static func _run_rest_of_game_loop(playing_field) -> void:
    # Finish the current turn
    if playing_field.turn_player == CardPlayer.BOTTOM:
        await playing_field.player_agent(CardPlayer.BOTTOM).run_one_turn(playing_field)
        await end_turn(playing_field, CardPlayer.BOTTOM)
        await _run_turn_for(playing_field, CardPlayer.TOP)
        await CardGamePhases.end_of_full_turn(playing_field)
    else:
        await playing_field.player_agent(CardPlayer.TOP).run_one_turn(playing_field)
        await end_turn(playing_field, CardPlayer.TOP)
        await CardGamePhases.end_of_full_turn(playing_field)

    while true:
        await CardGamePhases.start_of_full_turn(playing_field)
        await _run_turn_for(playing_field, CardPlayer.BOTTOM)
        await _run_turn_for(playing_field, CardPlayer.TOP)
        await CardGamePhases.end_of_full_turn(playing_field)


static func _run_turn_for(playing_field, player: StringName) -> void:
    await begin_turn(playing_field, player)
    await playing_field.player_agent(player).run_one_turn(playing_field)
    await end_turn(playing_field, player)


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
