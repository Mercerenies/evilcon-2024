extends EffectCardType


func get_id() -> int:
    return 31


func get_title() -> String:
    return "Ancient Scroll"


func get_text() -> String:
    return "+1 Level to all [icon]NINJA[/icon] NINJA cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 13


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.power_up_archetype(playing_field, card, Archetype.NINJA)
    await CardGameApi.destroy_card(playing_field, card)
