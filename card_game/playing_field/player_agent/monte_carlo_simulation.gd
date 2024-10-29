class_name MonteCarloSimulation
extends Node


class RunningSimulation:
    var _playing_field
    var _mutex
    var _winner

    func _init(playing_field) -> void:
        _playing_field = playing_field
        _mutex = Mutex.new()
        _winner = null

    func get_winner():
        _mutex.lock()
        var result = _winner
        _mutex.unlock()
        return result

    func is_finished():
        return get_winner() != null

    func _run() -> void:
        var game_result = await CardGameTurnTransitions.play_rest_of_game(_playing_field)
        _playing_field.free()
        _mutex.lock()
        _winner = game_result
        _mutex.unlock()


# Runs the current game until the endgame. Consumes the playing field.
#
# WARNING: This function runs code on a separate thread. The playing
# field passed to this function SHALL NOT be used by the current
# thread after calling this function. It belongs to the simulation
# thread after that point.
static func run_single_simulation(playing_field) -> RunningSimulation:
    var simulation = RunningSimulation.new(playing_field)
    WorkerThreadPool.add_task(simulation._run, false, "MonteCarloSimulation.run_single_simulation")
    return simulation
