extends EffectCardType


func get_id() -> int:
    return 156


func get_title() -> String:
    return "Laughing Gas"


func get_text() -> String:
    return "All enemy Minions are now of type [icon]CLOWN[/icon] CLOWN."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 163


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner

    var enemy_minions = (
        Query.on(playing_field).minions(CardPlayer.other(owner))
        .filter(Query.not_(Query.by_archetype(Archetype.CLOWN)))
        .array()
    )
    if len(enemy_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    for minion in enemy_minions:
        await _try_to_clown(playing_field, this_card, minion)


func _try_to_clown(playing_field, this_card, target_card):
    var can_influence = target_card.card_type.do_influence_check(playing_field, target_card, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, target_card, PopupText.CLOWNED)
        target_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = ai_get_score_base_calculation(playing_field, player, priorities)
    var opponent = CardPlayer.other(player)

    var opposing_minions_count = (
        Query.on(playing_field).minions(opponent)
        .filter([Query.not_(Query.by_archetype(Archetype.CLOWN)), Query.influenced_by(self, player)])
        .count()
    )
    score += priorities.of(LookaheadPriorities.CLOWNING) * opposing_minions_count

    return score
