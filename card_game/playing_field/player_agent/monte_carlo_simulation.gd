class_name MonteCarloSimulation
extends Node


const GreedyAIAgent = preload("res://card_game/playing_field/player_agent/greedy_ai_agent.tscn")


class RunningSimulation:
    var _playing_field
    var _mutex
    var _game_results

    func _init(playing_field) -> void:
        _playing_field = playing_field
        _mutex = Mutex.new()
        _game_results = null

    func get_results():
        _mutex.lock()
        var result = _game_results
        _mutex.unlock()
        return result

    func is_finished():
        return get_results() != null

    func _run_once() -> void:
        var winner = await CardGameTurnTransitions.play_rest_of_game(_playing_field)
        _playing_field.free()
        _mutex.lock()
        if winner == CardPlayer.BOTTOM:
            _game_results = { CardPlayer.BOTTOM: 1, CardPlayer.TOP: 0 }
        else:
            _game_results = { CardPlayer.BOTTOM: 0, CardPlayer.TOP: 1 }
        _mutex.unlock()

    func _run_several(n: int) -> void:
        var results = {
            CardPlayer.BOTTOM: 0,
            CardPlayer.TOP: 0,
        }
        for _i in range(n):
            var tmp_playing_field = Virtualization.to_virtual(_playing_field)
            tmp_playing_field.replace_player_agent(CardPlayer.BOTTOM, GreedyAIAgent.instantiate())
            tmp_playing_field.replace_player_agent(CardPlayer.TOP, GreedyAIAgent.instantiate())
            var winner = await CardGameTurnTransitions.play_rest_of_game(tmp_playing_field)
            tmp_playing_field.free()
            results[winner] += 1
        _playing_field.free()
        _mutex.lock()
        _game_results = results
        _mutex.unlock()


class BatchedSimulation:
    var _playing_field
    var _mutex
    var _remaining_batches
    var _game_results

    func _init(playing_field, total_batches) -> void:
        _playing_field = playing_field
        _mutex = Mutex.new()
        _remaining_batches = total_batches
        _game_results = {
            CardPlayer.BOTTOM: 0,
            CardPlayer.TOP: 0,
        }

    func get_results():
        _mutex.lock()
        var result = _game_results if _remaining_batches <= 0 else null
        _mutex.unlock()
        return result

    func is_finished():
        _mutex.lock()
        var result = (_remaining_batches <= 0)
        _mutex.unlock()
        return result

    func _run_several(_batch_index: int, n: int) -> void:
        var results = {
            CardPlayer.BOTTOM: 0,
            CardPlayer.TOP: 0,
        }
        for _i in range(n):
            var tmp_playing_field = Virtualization.to_virtual(_playing_field)
            tmp_playing_field.replace_player_agent(CardPlayer.BOTTOM, GreedyAIAgent.instantiate())
            tmp_playing_field.replace_player_agent(CardPlayer.TOP, GreedyAIAgent.instantiate())
            var winner = await CardGameTurnTransitions.play_rest_of_game(tmp_playing_field)
            print(tmp_playing_field.turn_number)
            tmp_playing_field.free()
            results[winner] += 1
        _mutex.lock()
        _game_results[CardPlayer.BOTTOM] += results[CardPlayer.BOTTOM]
        _game_results[CardPlayer.TOP] += results[CardPlayer.TOP]
        _remaining_batches -= 1
        if _remaining_batches <= 0:
            _playing_field.free()
        _mutex.unlock()


# Runs the current game until the endgame. Consumes the playing field.
#
# WARNING: This function runs code on a separate thread. The playing
# field passed to this function SHALL NOT be used by the current
# thread after calling this function. It belongs to the simulation
# thread after that point.
static func run_single_simulation(playing_field) -> RunningSimulation:
    var simulation = RunningSimulation.new(playing_field)
    WorkerThreadPool.add_task(simulation._run_once, false, "MonteCarloSimulation.run_single_simulation")
    return simulation


# Runs the current game until the endgame N times sequentially, where
# N must be nonnegative. Consumes the playing field.
#
# WARNING: This function runs code on a separate thread. The playing
# field passed to this function SHALL NOT be used by the current
# thread after calling this function. It belongs to the simulation
# thread after that point.
static func run_simulations_in_series(playing_field, n: int) -> RunningSimulation:
    var simulation = RunningSimulation.new(playing_field)
    WorkerThreadPool.add_task(simulation._run_several.bind(n), false, "MonteCarloSimulation.run_simulations_in_series")
    return simulation


# Runs the current game in parallel batches, accumulating all results.
#
# WARNING: This function runs code on a separate thread. The playing
# field passed to this function SHALL NOT be used by the current
# thread after calling this function. It belongs to the simulation
# thread after that point.
static func run_simulations(playing_field, batch_size: int, number_of_batches: int) -> BatchedSimulation:
    var simulation = BatchedSimulation.new(playing_field, number_of_batches)
    WorkerThreadPool.add_group_task(simulation._run_several.bind(batch_size), number_of_batches, -1, false, "MonteCarloSimulation.run_simulations")
    return simulation
