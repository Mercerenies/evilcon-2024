extends EffectCardType


func get_id() -> int:
    return 130


func get_title() -> String:
    return "Mystery Box"


func get_text() -> String:
    return "Create and immediately play a random card."


func get_star_cost() -> int:
    return 4


func get_picture_index() -> int:
    return 135


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    # ...
