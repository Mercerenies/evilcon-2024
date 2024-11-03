extends EffectCardType


func get_id() -> int:
    return 136


func get_title() -> String:
    return "Pet Cown"


func get_text() -> String:
    return "+1 Morale to your most powerful Minion for each [icon]CLOWN[/icon] CLOWN Minion your opponent controls, up to a maximum of 3."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 149


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _perform_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _perform_effect(playing_field, card) -> void:
    var owner = card.owner
    var opponent = CardPlayer.other(owner)
    var target_minion = CardEffects.most_powerful_minion(playing_field, owner)
    if target_minion == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    var opponent_clowns_count = (
        Query.on(playing_field).minions(opponent)
        .count(Query.by_archetype(Archetype.CLOWN))
    )
    await Stats.add_morale(playing_field, target_minion, min(opponent_clowns_count, 3))


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    var target_minion = CardEffects.most_powerful_minion(playing_field, player)
    var opponent_clowns_count = (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .count(Query.by_archetype(Archetype.CLOWN))
    )

    if target_minion != null:
        score += mini(opponent_clowns_count, 3) * target_minion.card_type.get_level(playing_field, target_minion) * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
