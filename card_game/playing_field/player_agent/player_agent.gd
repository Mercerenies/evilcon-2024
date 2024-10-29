class_name PlayerAgent
extends Node

# Abstract base class for agents that control players in the card game. These
# are usually either proxies to human input or AI algorithms to run
# the game.

@export_enum(&"BOTTOM", &"TOP") var controlled_player


func run_one_turn(_playing_field) -> void:
    # This required method should run one full iteration of the
    # player's turn, awaiting until that player has finished their
    # turn.
    push_warning("Forgot to override run_one_turn!")


func on_end_turn_button_pressed(_playing_field) -> void:
    # Called when the "End Turn" on-screen button is pressed. For
    # human-controlled agents, this should end the player's turn. For
    # AI agents, this should do nothing.
    push_warning("Forgot to override on_end_turn_button_pressed!")


func suppresses_input() -> bool:
    # True if this node should suppress human input on its own
    # player's turn.
    push_warning("Forgot to override suppresses_input!")
    return false


func deepclone():
    # Deep-copy the player agent. Subclasses should override this if
    # they define any additional instance fields that need to get
    # duplicated.
    var new_agent = get_script().new()
    new_agent.controlled_player = controlled_player
    return new_agent
