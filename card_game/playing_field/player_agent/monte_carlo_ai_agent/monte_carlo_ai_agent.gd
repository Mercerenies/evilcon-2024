extends PlayerAgent

const CardWatcher = preload("res://card_game/playing_field/card_watcher/card_watcher.gd")
const GreedyAIAgent = preload("res://card_game/playing_field/player_agent/greedy_ai_agent/greedy_ai_agent.tscn")


class PlayCardAction:
    var _card_index: int

    func _init(card_index: int):
        _card_index = card_index

    func description(playing_field, player: StringName) -> String:
        # For debugging
        return playing_field.get_hand(player).cards().card_array()[_card_index].get_title()

    func get_card(playing_field, player: StringName):
        return playing_field.get_hand(player).cards().peek_card(_card_index)

    func run_action_virtually(playing_field, player: StringName):
        var hand = playing_field.get_hand(player)
        var next_card_type = hand.cards().peek_card(_card_index)
        await CardGameApi.play_card_from_hand(playing_field, player, next_card_type)


class EndTurnAction:
    func description(_playing_field, _player: StringName) -> String:
        # For debugging
        return "(End)"

    func get_card(_playing_field, _player: StringName):
        return null

    func run_action_virtually(playing_field, player: StringName):
        # Simulate end of turn on a virtual playing field.
        await CardGameTurnTransitions.end_turn(playing_field, player)
        if player == CardPlayer.TOP:
            # End of full turn
            await CardGamePhases.end_of_full_turn(playing_field)
            await CardGamePhases.start_of_full_turn(playing_field)
        await CardGameTurnTransitions.begin_turn(playing_field, CardPlayer.other(player))


var _card_watcher = CardWatcher.new()


func added_to_playing_field(playing_field) -> void:
    super.added_to_playing_field(playing_field)
    playing_field.cards_moved.connect(_card_watcher._on_cards_moved.bind(playing_field, CardPlayer.other(controlled_player)))


func removed_from_playing_field(playing_field) -> void:
    super.removed_from_playing_field(playing_field)
    # HACK: Implementation hack in Godot 4.2.1.stable: Callables are
    # compared for equality (in disconnect) by their base name only,
    # ignoring any bindings. I sincerely hope this behavior stays this
    # way, as it's the only way to reliably disconnect a bound method
    # from a signal.
    playing_field.cards_moved.disconnect(_card_watcher._on_cards_moved.bind(playing_field, CardPlayer.other(controlled_player)))


func run_one_turn(playing_field) -> void:
    while true:
        var next_card_type = await _get_next_card(playing_field)
        if next_card_type == null:
            break  # Turn is done
        await CardGameApi.play_card_from_hand(playing_field, controlled_player, next_card_type)


func _get_next_card(playing_field):
    var legal_moves = _get_legal_moves(playing_field)
    if len(legal_moves) == 1:
        return legal_moves[0].get_card(playing_field, controlled_player)

    var simulations = legal_moves.map(func(move): return _run_simulation(playing_field, controlled_player, move))

    # Using our timer, poll until all simulations are done.
    while true:
        $AwaitThreadTimer.start()
        await $AwaitThreadTimer.timeout
        if simulations.all(func(sim): return sim.is_finished()):
            break

    var candidate_indices = range(len(legal_moves))

    # DEBUG CODE
    print(candidate_indices.map(func(idx):
        var results = simulations[idx].get_results()
        return [
            legal_moves[idx].description(playing_field, controlled_player),
            float(results[controlled_player]) / (results[controlled_player] + results[CardPlayer.other(controlled_player)]),
        ]))

    var chosen_index = Util.max_on(candidate_indices, func(idx):
        var results = simulations[idx].get_results()
        return float(results[controlled_player]) / (results[controlled_player] + results[CardPlayer.other(controlled_player)]))

    # DEUG CODE
    print(legal_moves[chosen_index].description(playing_field, controlled_player))

    return legal_moves[chosen_index].get_card(playing_field, controlled_player)


static func _run_simulation(playing_field, player: StringName, move):
    # TODO Fudge the data the AI shouldn't be able to see (deck order,
    # and opponent hand/deck contents)
    var virtual_playing_field = Virtualization.to_virtual(playing_field)
    move.run_action_virtually(virtual_playing_field, player)
    var simulation = MonteCarloSimulation.run_simulations(virtual_playing_field, 10, 4)
    return simulation


func _get_legal_moves(playing_field):
    var legal_moves = []
    var hand_cards = playing_field.get_hand(controlled_player).cards().card_array()
    for index in range(len(hand_cards)):
        var card_type = hand_cards[index]
        if card_type.can_play(playing_field, controlled_player):
            legal_moves.push_back(PlayCardAction.new(index))
    legal_moves.push_back(EndTurnAction.new())
    return legal_moves


func on_end_turn_button_pressed(_playing_field) -> void:
    # AI-controlled agent; ignore user input.
    pass


func suppresses_input() -> bool:
    return true
