class_name TimedCardType
extends EffectCardType

# A TimedCardType is an EffectCardType that lasts a certain number of
# turns and displays its turn counter on the UI. TimedCardTypes count
# up during the Standby Phase.


func is_ongoing() -> bool:
    return true


func get_total_turn_count() -> int:
    push_warning("Forgot to override get_total_turn_count!")
    return 0


func on_instantiate(card) -> void:
    super.on_instantiate(card)
    card.metadata[CardMeta.TURN_COUNTER] = 0


func get_overlay_text(_playing_field, card) -> String:
    var turn_counter = card.metadata[CardMeta.TURN_COUNTER]
    return "Turn %s" % (turn_counter + 1)


func on_standby_phase(playing_field, card) -> void:
    super.on_standby_phase(playing_field, card)
    if playing_field.turn_player == card.owner:
        card.metadata[CardMeta.TURN_COUNTER] += 1
        playing_field.emit_cards_moved()
        if card.metadata[CardMeta.TURN_COUNTER] >= get_total_turn_count():
            await CardGameApi.destroy_card(playing_field, card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    score += ai_get_score_per_turn(playing_field, player, priorities) * get_total_turn_count()
    return score


func ai_get_score_per_turn(_playing_field, _player: StringName, _priorities) -> float:
    # The value of this TimedCardType remaining on the field for one
    # turn. Subclasses should generally prefer to override this method
    # rather than ai_get_score, because this method iwll also interact
    # correctly with cards that extend lifetimes, like Chris Cogsworth
    # or the Foreman.
    return 0.0
