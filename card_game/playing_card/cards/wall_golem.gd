extends EffectCardType


func get_id() -> int:
    return 95


func get_title() -> String:
    return "Wall Golem"


func get_text() -> String:
    return "+4 defense to your own fortress."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 129


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Effect was blocked
        return

    await Stats.add_fort_defense(playing_field, owner, 4)
