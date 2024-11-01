extends PlayerAgent

# Player agent for the human player. Accepts input from the human in
# front of the computer.

var _end_of_turn_promise = null


func run_one_turn(_playing_field) -> void:
    _end_of_turn_promise = Promise.new()
    await _end_of_turn_promise.async_awaiter()
    _end_of_turn_promise = null


func on_end_turn_button_pressed(_playing_field) -> void:
    if _end_of_turn_promise != null:
        _end_of_turn_promise.resolve()


func suppresses_input() -> bool:
    return false
