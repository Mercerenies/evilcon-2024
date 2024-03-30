extends Node2D

const CardMovingAnimation = preload("res://card_game/playing_field/animation/card_moving_animation.tscn")
const PlayingCardDisplay = preload("res://card_game/playing_card/playing_card_display/playing_card_display.tscn")
const BlankCardDisplay = preload("res://card_game/playing_card/blank_card_display/blank_card_display.tscn")
const HiddenCardDisplay = preload("res://card_game/playing_card/hidden_card_display/hidden_card_display.tscn")
const ScrollableCardRow = preload("res://card_game/scrollable_card_row/scrollable_card_row.tscn")
const NullMinion = preload("res://card_game/playing_card/cards/null_minion.gd")
const NullEnemyAI = preload("res://card_game/playing_field/enemy_ai/null_enemy_ai.gd")
const Randomness = preload("res://card_game/playing_field/randomness.gd")

# Emitted anytime the state of the board changes. This includes cards
# being added, removed, shuffled, or having their stats modified in
# any player's discard pile, deck, hand, minion strip, or effect
# strip.
signal cards_moved

signal turn_number_updated
signal turn_player_changed

# Note: This starts at -1 but will be set to 0 as soon as the game
# starts. The first turn of the game is internally treated as Turn 0.
var turn_number: int = -1:
    set(v):
        turn_number = v
        turn_number_updated.emit()

var turn_player: StringName = CardPlayer.BOTTOM:
    set(v):
        turn_player = v
        turn_player_changed.emit()

var _enemy_ai: Node = NullEnemyAI.new()

var randomness = Randomness.new()

func _ready() -> void:
    # Make sure initial stats are correct.
    $BottomStats.update_stats_from(self, CardPlayer.BOTTOM)
    $TopStats.update_stats_from(self, CardPlayer.TOP)
    $AILayer.add_child(_enemy_ai)


func replace_enemy_ai(new_enemy_ai: Node) -> void:
    var is_in_tree = _enemy_ai.is_inside_tree()
    _enemy_ai.free()
    _enemy_ai = new_enemy_ai
    if is_in_tree:
        $AILayer.add_child(_enemy_ai)


func get_animation_layer() -> Node2D:
    return $AnimationLayer


func get_deck(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomDeck
    elif player == CardPlayer.TOP:
        return $TopDeck
    else:
        push_error("Bad card player %s" % player)
        return null


func get_discard_pile(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomDiscardPile
    elif player == CardPlayer.TOP:
        return $TopDiscardPile
    else:
        push_error("Bad card player %s" % player)
        return null


func get_hand(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomHand
    elif player == CardPlayer.TOP:
        return $TopHand
    else:
        push_error("Bad card player %s" % player)
        return null


func get_minion_strip(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomMinionStrip
    elif player == CardPlayer.TOP:
        return $TopMinionStrip
    else:
        push_error("Bad card player %s" % player)
        return null


func get_effect_strip(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomEffectStrip
    elif player == CardPlayer.TOP:
        return $TopEffectStrip
    else:
        push_error("Bad card player %s" % player)
        return null


func get_stats(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomStats
    elif player == CardPlayer.TOP:
        return $TopStats
    else:
        push_error("Bad card player %s" % player)
        return null


func field_strips() -> Array:
    return [$BottomMinionStrip, $TopMinionStrip, $BottomEffectStrip, $TopEffectStrip]


# Moves a card from one node to another.
#
# The source and destination nodes must have a method called cards()
# which returns the appropriate CardContainer.
#
# Optional arguments are as follows:
#
# * source_index (int) - Index to draw from in the source node's
#   CardContainer. Counts from the back if negative. Default = -1.
#
# * scale (Vector2) - Scale of the animation. Default = Vector2(0.25, 0.25).
#
# * custom_displayed_card (Callable) - A 0-argument Callable that
#   returns a card display node (a node with a set_card() method) to
#   use. If not provided, the default node type of PlayingCardDisplay
#   is used.
#
# * destination_transform (Callable) - A 1-argument Callable that
#   transforms the drawn card before it is stored in the destination.
#   If not supplied, defaults to the identity function.
func move_card(source, destination, opts = {}):
    var source_index = opts.get("source_index", -1)
    var animation_scale = opts.get("scale", Vector2(0.25, 0.25))
    var custom_displayed_card = opts.get("custom_displayed_card", null)
    var destination_transform = opts.get("destination_transform", null)

    # TODO In some situations we should consider rotating the
    # animation 180 degrees, for instance if a card is being moved
    # from enemy hand to field, or from enemy field to discard.

    var source_cards = source.cards()
    var destination_cards = destination.cards()
    var relevant_card = source_cards.pop_card(source_index)
    emit_cards_moved()

    # Animate the card moving
    var animation = CardMovingAnimation.instantiate()
    $AnimationLayer.add_child(animation)
    animation.scale = animation_scale
    if custom_displayed_card != null:
        animation.replace_displayed_card(custom_displayed_card.call())
    animation.set_card(relevant_card)
    await animation.animate(source.position, destination.position)
    animation.queue_free()

    if destination_transform != null:
        relevant_card = destination_transform.call(relevant_card)
    destination_cards.push_card(relevant_card)
    emit_cards_moved()
    return relevant_card


func _on_bottom_hand_card_added(card_node):
    card_node.card_clicked.connect(_on_bottom_hand_card_node_card_clicked.bind(card_node))
    card_node.card_right_clicked.connect(_on_bottom_hand_card_node_card_right_clicked.bind(card_node))


func _on_top_hand_card_added(card_node):
    card_node.clickable = true
    card_node.card_clicked.connect(_on_top_hand_card_node_card_clicked)


func _on_play_strip_card_added(card_node):
    card_node.card_clicked.connect(_on_played_card_node_card_clicked.bind(card_node))


func _on_top_hand_card_node_card_clicked() -> void:
    popup_display_card([NullMinion.new()], {
        "custom_displayed_card": func(): return HiddenCardDisplay,
    })



func _on_bottom_hand_card_node_card_clicked(card_node) -> void:
    var card_type = card_node.card_type
    var card_row = popup_display_card([card_type], {
        "margin_below": 64.0,
    })

    var play_button = Button.new()
    if card_type.can_play(self, CardPlayer.BOTTOM):
        play_button.text = "Play"
        play_button.pressed.connect(func play_card_and_free_ui():
            CardGameApi.play_card(self, CardPlayer.BOTTOM, card_type)
            card_row.queue_free())
    else:
        play_button.text = "(Can't afford)"
        play_button.disabled = true
    card_row.append_button(play_button)


func _on_bottom_hand_card_node_card_right_clicked(card_node) -> void:
    var card_type = card_node.card_type
    if card_type.can_play(self, CardPlayer.BOTTOM):
        CardGameApi.play_card(self, CardPlayer.BOTTOM, card_type)


func _on_played_card_node_card_clicked(card_node) -> void:
    var card_type = card_node.card_type
    popup_display_card([card_type])


# Shows a ScrollableCardRow for the indicated card types (or cards, if
# supported by the underlying display scene).
#
# Optional arguments are as follows:
#
# * margin_below (float) - Margin below the card row (in pixels).
#
# * margin_above (float) - Margin above the card row (in pixels).
#
# * custom_displayed_card (Callable) - A 0-argument Callable that
#   returns a card display node (a node with a set_card() method) to
#   use. If not provided, the default node type of PlayingCardDisplay
#   is used.
func popup_display_card(cards: Array, opts = {}) -> Node2D:
    var margin_below = opts.get("margin_below", null)
    var margin_above = opts.get("margin_above", null)
    var custom_displayed_card = opts.get("custom_displayed_card", null)

    var viewport_size = get_viewport().get_visible_rect()
    var card_row = ScrollableCardRow.instantiate()
    if margin_below != null:
        card_row.margin_below = margin_below
    if margin_above != null:
        card_row.margin_above = margin_above
    if custom_displayed_card == null:
        card_row.card_display_scene = PlayingCardDisplay
    else:
        card_row.card_display_scene = custom_displayed_card.call()
    $UILayer.add_child(card_row)
    card_row.cards().replace_cards(cards)
    card_row.position = Vector2(0, viewport_size.size.y / 2)
    return card_row


func _show_discard_pile(pile_node):
    var array = pile_node.cards().card_array()
    var opts = {}
    if len(array) == 0:
        array = [NullMinion.new()]
        opts["custom_displayed_card"] = func(): return BlankCardDisplay
    var card_row = popup_display_card(array, opts)
    card_row.set_scroll_position(1.0)  # Scroll to the right
    return card_row


func _show_deck(deck_size: int):
    var array = []
    array.resize(deck_size)
    for i in range(deck_size):
        array[i] = NullMinion.new()
    var card_row = popup_display_card(array, {
        "custom_displayed_card": func(): return HiddenCardDisplay,
    })
    card_row.set_scroll_position(1.0)  # Scroll to the right
    return card_row


func _on_bottom_discard_pile_pile_clicked():
    _show_discard_pile($BottomDiscardPile)


func _on_top_discard_pile_pile_clicked():
    _show_discard_pile($TopDiscardPile)


func _on_top_deck_pile_clicked():
    _show_deck($TopDeck.cards().card_count())


func _on_bottom_deck_pile_clicked():
    _show_deck($BottomDeck.cards().card_count())


func emit_cards_moved() -> void:
    cards_moved.emit()


func _on_cards_moved():
    $BottomStats.update_stats_from(self, CardPlayer.BOTTOM)
    $TopStats.update_stats_from(self, CardPlayer.TOP)
    # Update all cards in play
    for card in $BottomMinionStrip.card_nodes():
        _refresh_card_stats(card)
    for card in $TopMinionStrip.card_nodes():
        _refresh_card_stats(card)
    for card in $BottomEffectStrip.card_nodes():
        _refresh_card_stats(card)
    for card in $TopEffectStrip.card_nodes():
        _refresh_card_stats(card)


func _refresh_card_stats(card_node):
    card_node.overlay_text = card_node.card.get_overlay_text(self)
    card_node.overlay_icons = card_node.card.get_overlay_icons(self)


func _on_turn_number_updated():
    $BottomStats.update_stats_from(self, CardPlayer.BOTTOM)
    $TopStats.update_stats_from(self, CardPlayer.TOP)


func _on_turn_player_changed():
    $EndTurnButton.disabled = (turn_player != CardPlayer.BOTTOM)


func _on_end_turn_button_pressed():
    await CardGameTurnTransitions.end_turn(self, CardPlayer.BOTTOM)
    await CardGameTurnTransitions.begin_turn(self, CardPlayer.TOP)
    _enemy_ai.start_enemy_turn(self)


func end_enemy_turn() -> void:
    # Do NOT call this directly from an EnemyAI subclass. Call
    # EnemyAI.end_enemy_turn, which delegates to this method instead.
    # (Yes, it's spaghetti and I should probably clean that up)
    #
    # TODO Good visuals for turn transitions
    await CardGameTurnTransitions.end_turn(self, CardPlayer.TOP)
    await CardGamePhases.end_of_full_turn(self)
    await CardGamePhases.start_of_full_turn(self)
    await CardGameTurnTransitions.begin_turn(self, CardPlayer.BOTTOM)
