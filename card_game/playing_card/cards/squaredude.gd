extends EffectCardType


func get_id() -> int:
    return 90


func get_title() -> String:
    return "Squaredude"


func get_text() -> String:
    return "+1 Level to your most powerful Minion, or +1 Level to all of your Minions if you successfully played Circlegirl this turn."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 79


func is_hero() -> bool:
    return true


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    await CardGameApi.highlight_card(playing_field, card)

    if not await CardEffects.do_hero_check(playing_field, card):
        # Blocked by Hero-blocking card
        return

    playing_field.event_logger.log_event(playing_field.turn_number, owner, LogEvents.SQUAREDUDE_PLAYED)

    var targets
    if playing_field.event_logger.has_event(playing_field.turn_number, owner, LogEvents.CIRCLEGIRL_PLAYED):
        # Circlegirl was played, level up all Minions
        targets = playing_field.get_minion_strip(owner).cards().card_array()
    else:
        # No Circlegirl, so only target the most powerful Minion
        var single_target = CardEffects.most_powerful_minion(playing_field, owner)
        targets = [single_target] if single_target != null else []

    if len(targets) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return

    for target in targets:
        var can_influence = target.card_type.do_influence_check(playing_field, target, card, false)
        if can_influence:
            await Stats.add_level(playing_field, target, 1)
