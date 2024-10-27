extends Node2D

const DESTINY_SONG_LIMIT := 3

const DEFAULT_FORT_DEFENSE := 60

# Note: Stats which are themselves stateful (e.g., fort defense, max
# fort defense, current evil point count, and current destiny song
# count) are stored here as instance variables. That is, this object
# is the source of truth for those values. Other values (EP per turn,
# hand limit) are calculated from the state of the playing field and
# are merely *displayed* here.

var evil_points: int = 0:
    set(v):
        evil_points = maxi(v, 0)
        _update_evil_points()

# We store this whenever we get an update from the playing field. This
# IS NOT the source of truth for this value. The source of truth for
# this value is StatsCalculator.get_evil_points_per_turn. This is
# merely our log of the last change to this value, so we can correctly
# update the UI when evil_points gets changed.
var _evil_points_per_turn: int = 0

var fort_defense: int = DEFAULT_FORT_DEFENSE:
    set(v):
        fort_defense = clampi(v, 0, max_fort_defense)
        _update_fort_defense()

var max_fort_defense: int = DEFAULT_FORT_DEFENSE:
    set(v):
        max_fort_defense = maxi(v, 0)
        self.fort_defense = fort_defense  # Refresh value with new limit
        _update_fort_defense()

var destiny_song: int = 0:
    set(v):
        destiny_song = clampi(v, 0, DESTINY_SONG_LIMIT)
        _update_destiny_song()


func get_evil_points_node() -> Node2D:
    return $EvilPointsStat


func get_hand_limit_node() -> Node2D:
    return $HandLimitStat


func get_fort_defense_node() -> Node2D:
    return $FortDefenseStat


func get_destiny_song_node() -> Node2D:
    return $DestinySongStat


func _update_evil_points() -> void:
    $EvilPointsStat.text = "%s/%s" % [evil_points, _evil_points_per_turn]


func _update_hand_limit(playing_field, player: StringName) -> void:
    var hand_size = playing_field.get_hand(player).cards().card_count()
    var hand_limit = StatsCalculator.get_hand_limit(playing_field, player)
    $HandLimitStat.text = "%s/%s" % [hand_size, hand_limit]


func _update_fort_defense() -> void:
    $FortDefenseStat.text = "%s/%s" % [fort_defense, max_fort_defense]


func _update_destiny_song() -> void:
    $DestinySongStat.text = "%s/%s" % [destiny_song, DESTINY_SONG_LIMIT]
    $DestinySongStat.visible = (destiny_song > 0)


func update_stats_from(playing_field, player: StringName) -> void:
    _evil_points_per_turn = StatsCalculator.get_evil_points_per_turn(playing_field, player)
    _update_evil_points()
    _update_hand_limit(playing_field, player)
    _update_fort_defense()
    _update_destiny_song()
