extends EffectCardType


func get_id() -> int:
    return 175


func get_title() -> String:
    return "Turtles Unite!"


func get_text() -> String:
    return "[font_size=12]Destroy all [icon]TURTLE[/icon] TURTLE Minions you control; +X defense to your fortress, where X is twice the total Level of the destroyed Minions. Limit 1 per deck.[/font_size]"


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 172


func is_limited() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _get_cards_to_destroy(playing_field, owner: StringName) -> Array:
    return (
        Query.on(playing_field).minions(owner)
        .filter(Query.by_archetype(Archetype.TURTLE))
        .array()
    )


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var cards_to_destroy = _get_cards_to_destroy(playing_field, owner)
    if len(cards_to_destroy) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var total_level = 0
    for card in cards_to_destroy:
        var can_influence = card.card_type.do_influence_check(playing_field, card, this_card, false)
        if can_influence:
            total_level += 2 * card.card_type.get_level(playing_field, card)
            await CardGameApi.destroy_card(playing_field, card)
    if total_level > 0:
        await Stats.add_fort_defense(playing_field, owner, total_level)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Add in the prospective heal amount and subtract the cost of
    # destroying the relevant minions.
    var stats = playing_field.get_stats(player)
    var heal_amount = 0
    var relevant_minions = _get_cards_to_destroy(playing_field, player)
    for minion in relevant_minions:
        var can_influence = CardEffects.do_hypothetical_influence_check(playing_field, minion, self, player)
        if can_influence:
            heal_amount += 2 * minion.card_type.get_level(playing_field, minion)
            score -= minion.card_type.ai_get_value_of_destroying(playing_field, minion, priorities)
    heal_amount = mini(heal_amount, stats.max_fort_defense - stats.fort_defense)
    score += heal_amount * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
