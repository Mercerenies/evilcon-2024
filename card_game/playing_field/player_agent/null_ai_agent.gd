extends PlayerAgent

# NullAIAgent does nothing. At all. He just passes his turn.
#
# Note that this is used as the default null object in several places.
# Since it has a distinguished position as a null value, NullAIAgent's
# added_to_playing_field and removed_from_playing_field methods may or
# may not get called and thus should be no-ops.

func run_one_turn(_playing_field) -> void:
    # Do nothing.
    pass


func on_end_turn_button_pressed(_playing_field) -> void:
    # AI-controlled agent; ignore user input.
    pass


func suppresses_input() -> bool:
    return true
