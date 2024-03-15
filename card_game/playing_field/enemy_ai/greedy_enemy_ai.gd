extends EnemyAI

# GreedyEnemyAI randomly picks cards from hand to play until he can't
# anymore. He has no concept of strategy or of which cards are better.


func on_enemy_turn_start(playing_field) -> void:
    while true:
        $NextActionTimer.start()
        await $NextActionTimer.timeout
        var next_card_type = _get_next_card(playing_field)
        if next_card_type == null:
            break  # Turn is done
        await CardGameApi.play_card(playing_field, CardPlayer.TOP, next_card_type)
    end_enemy_turn(playing_field)


func _get_next_card(playing_field):
    var hand = playing_field.get_hand(CardPlayer.TOP)
    var playable_cards = hand.cards().card_array().filter(
        func(card_type): return card_type.can_play(playing_field, CardPlayer.TOP)
    )
    if playable_cards.is_empty():
        return null
    return playable_cards.pick_random()
