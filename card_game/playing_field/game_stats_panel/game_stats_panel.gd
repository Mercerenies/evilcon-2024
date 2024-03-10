extends Node2D

const DESTINY_SONG_LIMIT := 3


var evil_points: int = 2:
    set(v):
        evil_points = maxi(v, 0)
        _update_evil_points()

var evil_points_per_turn: int = 2:
    set(v):
        evil_points_per_turn = maxi(v, 0)
        _update_evil_points()

var hand_limit: int = 5:
    set(v):
        hand_limit = maxi(v, 0)
        _update_hand_limit()

var fort_defense: int = 100:
    set(v):
        fort_defense = clampi(v, 0, max_fort_defense)
        _update_fort_defense()

var max_fort_defense: int = 100:
    set(v):
        max_fort_defense = maxi(v, 0)
        self.fort_defense = fort_defense  # Refresh value with new limit
        _update_fort_defense()

var destiny_song: int = 0:
    set(v):
        destiny_song = clampi(v, 0, DESTINY_SONG_LIMIT)
        _update_destiny_song()

var _last_known_hand_size: int = 0


func _ready() -> void:
    _update_evil_points()
    _update_hand_limit()
    _update_fort_defense()
    _update_destiny_song()


func on_hand_size_updated(new_hand_size: int) -> void:
    _last_known_hand_size = new_hand_size
    _update_hand_limit()


func _update_evil_points() -> void:
    $EvilPointsStat.text = "%s/%s" % [evil_points, evil_points_per_turn]


func _update_hand_limit() -> void:
    $HandLimitStat.text = "%s/%s" % [_last_known_hand_size, hand_limit]


func _update_fort_defense() -> void:
    $FortDefenseStat.text = "%s/%s" % [fort_defense, max_fort_defense]


func _update_destiny_song() -> void:
    $DestinySongStat.text = "%s/%s" % [destiny_song, DESTINY_SONG_LIMIT]
    $DestinySongStat.visible = (destiny_song > 0)
