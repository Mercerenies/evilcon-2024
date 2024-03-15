extends EnemyAI

# Basic Enemy AI that never does anything. Used for debugging.

func on_enemy_turn_start(playing_field) -> void:
    # Immediately end enemy turn
    end_enemy_turn(playing_field)
