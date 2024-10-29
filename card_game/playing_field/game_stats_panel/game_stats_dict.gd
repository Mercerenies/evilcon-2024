extends Node

const DESTINY_SONG_LIMIT := 3
const DEFAULT_FORT_DEFENSE := 60

var evil_points: int = 0:
    set(v):
        evil_points = maxi(v, 0)

var fort_defense: int = DEFAULT_FORT_DEFENSE:
    set(v):
        fort_defense = clampi(v, 0, max_fort_defense)

var max_fort_defense: int = DEFAULT_FORT_DEFENSE:
    set(v):
        max_fort_defense = maxi(v, 0)
        self.fort_defense = fort_defense  # Refresh value with new limit

var destiny_song: int = 0:
    set(v):
        destiny_song = clampi(v, 0, DESTINY_SONG_LIMIT)


func load_stats_from(other_stats_panel) -> void:
    evil_points = other_stats_panel.evil_points
    fort_defense = other_stats_panel.fort_defense
    max_fort_defense = other_stats_panel.max_fort_defense
    destiny_song = other_stats_panel.destiny_song
