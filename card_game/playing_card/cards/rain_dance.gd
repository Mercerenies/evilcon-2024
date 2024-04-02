extends EffectCardType


func get_id() -> int:
    return 43


func get_title() -> String:
    return "Rain Dance"


func get_text() -> String:
    return "+1 Level to all [icon]NATURE[/icon] NATURE cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 64


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.power_up_archetype(playing_field, card, Archetype.NATURE)
    await CardGameApi.destroy_card(playing_field, card)
