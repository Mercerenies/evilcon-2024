extends EffectCardType


const TARGET_ARCHETYPES = [Archetype.FARM, Archetype.BEE, Archetype.NATURE, Archetype.TURTLE]


func get_id() -> int:
    return 147


func get_title() -> String:
    return "Greener Pastures"


func get_text() -> String:
    return "+1 Level to all [icon]FARM[/icon] FARM, [icon]BEE[/icon] BEE, [icon]NATURE[/icon] NATURE, and [icon]TURTLE[/icon] TURTLE cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 171


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await CardEffects.power_up_archetype(playing_field, card, TARGET_ARCHETYPES)
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    return (
        super.ai_get_score(playing_field, player, priorities) +
        CardEffects.ai_score_for_powering_up_archetype(playing_field, self, player, TARGET_ARCHETYPES, priorities)
    )
