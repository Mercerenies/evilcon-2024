extends EffectCardType


func get_id() -> int:
    return 53


func get_title() -> String:
    return "Milk Delivery"


func get_text() -> String:
    return "+1 Morale to all Minions currently in play, regardless of owner."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 23


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)

    var minions = Query.on(playing_field).minions().array()

    if len(minions) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        for minion in minions:
            await Stats.add_morale(playing_field, minion, 1)
    await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var defense_points = (
        Query.on(playing_field).minions(player)
        .map_sum(Query.level().value())
    ) - (
        Query.on(playing_field).minions(CardPlayer.other(player))
        .map_sum(Query.level().value())
    )
    score += defense_points * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
