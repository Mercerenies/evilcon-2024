extends RefCounted

# Every PlayingField has an EventLogger. This is NOT intended to log
# all events, and indeed by default it logs absolutely nothing.
# However, playing cards can send events to this log, so that they can
# keep track of things that happened at a global level in the game.
#
# Note that, for things local to one card, CardMeta should be
# preferred. The EventLogger is intended for events that affect
# multiple cards.

var _dict := {}


func _dict_key(turn_number: int, player: StringName) -> int:
    # We store data in the dictionary using 2 * turn_number + player
    # (where player is zero for BOTTOM and one for TOP). This is an
    # implementation detail that users should not need to worry about.
    var player_value = 0 if player == CardPlayer.BOTTOM else 1
    return 2 * turn_number + player_value


func _get_events(turn_number: int, player: StringName) -> Array:
    var key = _dict_key(turn_number, player)
    if not (key in _dict):
        _dict[key] = []
    return _dict[key]


func log_event(turn_number: int, player: StringName, event: StringName) -> void:
    _get_events(turn_number, player).push_back(event)


func has_event(turn_number: int, player: StringName, event: StringName) -> bool:
    return event in _get_events(turn_number, player)
