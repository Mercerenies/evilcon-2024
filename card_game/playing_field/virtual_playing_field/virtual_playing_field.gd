extends Node

# This class aims to be compatible with the PlayingField interface,
# but without any of the animations or on-screen displays. Intended to
# be used internally by AI engines to simulate the game.

const Randomness = preload("res://card_game/playing_field/randomness.gd")
const EventLogger = preload("res://card_game/playing_field/event_logger/EventLogger.cs")
const NullAIAgent = preload("res://card_game/playing_field/player_agent/null_ai_agent.gd")

signal cards_moved
signal turn_number_updated
signal turn_player_changed

signal _never

signal game_ended(winner)

var turn_number: int = -1:
    set(v):
        turn_number = v
        turn_number_updated.emit()

var turn_player: StringName = CardPlayer.BOTTOM:
    set(v):
        turn_player = v
        turn_player_changed.emit()

var _top_agent: Node = NullAIAgent.new()
var _bottom_agent: Node = NullAIAgent.new()

var randomness = Randomness.new()
var event_logger = EventLogger.new()

var _ai_initialized := false


# Since this node will (likely) never be added to
# the scene tree, we have to manually initialize
# the AI agents. This must be done once, before
# using the VirtualPlayingField for any card-
# game-related reasons.
func init_ai_agents() -> void:
    if _ai_initialized:
        push_warning("init_ai_agents was called multiple times")
        return
    $AIAgents.add_child(_top_agent)
    $AIAgents.add_child(_bottom_agent)
    _ai_initialized = true


func replace_player_agent(player: StringName, new_agent: Node) -> void:
    var old_agent = _top_agent if player == CardPlayer.TOP else _bottom_agent
    old_agent.removed_from_playing_field(self)
    old_agent.free()
    new_agent.controlled_player = player
    if player == CardPlayer.TOP:
        _top_agent = new_agent
    else:
        _bottom_agent = new_agent
    new_agent.added_to_playing_field(self)
    $AIAgents.add_child(new_agent)


func with_animation(_unused_callable):
    # VirtualPlayingField does not play animations.
    return null


func get_deck(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomDeck
    elif player == CardPlayer.TOP:
        return $TopDeck
    else:
        push_error("Bad card player %s" % player)
        return null


func get_discard_pile(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomDiscardPile
    elif player == CardPlayer.TOP:
        return $TopDiscardPile
    else:
        push_error("Bad card player %s" % player)
        return null


func get_hand(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomHand
    elif player == CardPlayer.TOP:
        return $TopHand
    else:
        push_error("Bad card player %s" % player)
        return null


func get_minion_strip(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomMinionStrip
    elif player == CardPlayer.TOP:
        return $TopMinionStrip
    else:
        push_error("Bad card player %s" % player)
        return null


func get_effect_strip(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomEffectStrip
    elif player == CardPlayer.TOP:
        return $TopEffectStrip
    else:
        push_error("Bad card player %s" % player)
        return null


func get_stats(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomStats
    elif player == CardPlayer.TOP:
        return $TopStats
    else:
        push_error("Bad card player %s" % player)
        return null


func animate_card_moving(_source, _destination, _card, _opts = {}):
    # We don't play animations in the VirtualPlayingField.
    pass


func emit_cards_moved() -> void:
    cards_moved.emit()


func end_game(winner: StringName) -> void:
    game_ended.emit(winner)
    await _never


func hand_cards_are_hidden(_player) -> bool:
    return true


func player_agent(player: StringName):
    return _top_agent if player == CardPlayer.TOP else _bottom_agent


func get_viewport_rect() -> Rect2:
    return Rect2()
