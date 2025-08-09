extends EffectCardType


const TARGET_ARCHETYPES = [Archetype.DEMON, Archetype.UNDEAD]


func get_id() -> int:
    return 200


func get_title() -> String:
    return "River Styx"


func get_text() -> String:
    return "+1 Level to all [icon]DEMON[/icon] DEMON and [icon]UNDEAD[/icon] UNDEAD cards currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 217


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
