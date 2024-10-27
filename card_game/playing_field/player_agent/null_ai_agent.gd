extends PlayerAgent

# GreedyEnemyAI randomly picks cards from hand to play until he can't
# anymore. He has no concept of strategy or of which cards are better.

func run_one_turn(_playing_field) -> void:
    # Do nothing.
    pass


func on_end_turn_button_pressed(_playing_field) -> void:
    # AI-controlled agent; ignore user input.
    pass


func suppresses_input() -> bool:
    return true
