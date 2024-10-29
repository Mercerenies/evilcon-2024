extends PlayerAgent

const CardWatcher = preload("res://card_game/playing_field/card_watcher/card_watcher.gd")

# (While I set up the Monte Carlo sim, this just uses GreedyAIAgent's
# logic. TODO Do NOT leave it this way!)


var _card_watcher = CardWatcher.new()


func added_to_playing_field(playing_field) -> void:
    super.added_to_playing_field(playing_field)
    playing_field.cards_moved.connect(_card_watcher._on_cards_moved.bind(playing_field, CardPlayer.other(controlled_player)))


func removed_from_playing_field(playing_field) -> void:
    super.removed_from_playing_field(playing_field)
    # HACK: Implementation hack in Godot 4.2.1.stable: Callables are
    # compared for equality (in disconnect) by their base name only,
    # ignoring any bindings. I sincerely hope this behavior stays this
    # way, as it's the only way to reliably disconnect a bound method
    # from a signal.
    playing_field.cards_moved.disconnect(_card_watcher._on_cards_moved.bind(playing_field, CardPlayer.other(controlled_player)))


func run_one_turn(playing_field) -> void:
    while true:
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
