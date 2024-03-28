extends EffectCardType

# /////


func get_id() -> int:
    return 29


func get_title() -> String:
    return "Pasta Power!"


func get_text() -> String:
    return "+1 Level to all [icon]PASTA[/icon] PASTA cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 63


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    # ...
    pass
