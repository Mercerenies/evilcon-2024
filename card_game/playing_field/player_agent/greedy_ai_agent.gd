extends PlayerAgent

# GreedyEnemyAI randomly picks cards from hand to play until he can't
# anymore. He has no concept of strategy or of which cards are better.

func run_one_turn(playing_field) -> void:
    while true:
        $NextActionTimer.start()
        await $NextActionTimer.timeout
        var next_card_type = _get_next_card(playing_field)
        if next_card_type == null:
            break  # Turn is done
        await CardGameApi.play_card_from_hand(playing_field, controlled_player, next_card_type)


func _get_next_card(playing_field):
    var hand = playing_field.get_hand(controlled_player)
    var playable_cards = hand.cards().card_array().filter(
        func(card_type): return card_type.can_play(playing_field, controlled_player)
    )
    if playable_cards.is_empty():
        return null
    return playable_cards.pick_random()


func on_end_turn_button_pressed(_playing_field) -> void:
    # AI-controlled agent; ignore user input.
    pass


func suppresses_input() -> bool:
    return true
