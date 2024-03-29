extends EffectCardType


func get_id() -> int:
    return 45


func get_title() -> String:
    return "Power Surge"


func get_text() -> String:
    return "+1 Level to all [icon]ROBOT[/icon] ROBOT cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 67


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.power_up_archetype(playing_field, card, Archetype.ROBOT)
    await CardGameApi.destroy_card(playing_field, card)
