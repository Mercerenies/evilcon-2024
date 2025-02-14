extends EffectCardType


func get_id() -> int:
    return 42


func get_title() -> String:
    return "Mirror Crystal"


func get_text() -> String:
    return "+1 Level to all [icon]SHAPE[/icon] SHAPE cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 10


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.power_up_archetype(playing_field, card, Archetype.SHAPE)
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    return (
        super.ai_get_score(playing_field, player, priorities) +
        CardEffects.ai_score_for_powering_up_archetype(playing_field, self, player, Archetype.SHAPE, priorities)
    )
