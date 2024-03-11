extends Node2D

const CardMovingAnimation = preload("res://card_game/playing_field/animation/card_moving_animation.tscn")
const NumberAnimation = preload("res://card_game/playing_field/animation/number_animation.tscn")
const PlayingCardDisplay = preload("res://card_game/playing_card/playing_card_display/playing_card_display.tscn")
const HiddenCardDisplay = preload("res://card_game/playing_card/hidden_card_display/hidden_card_display.tscn")
const ScrollableCardRow = preload("res://card_game/scrollable_card_row/scrollable_card_row.tscn")


func get_deck(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomDeck
    elif player == CardPlayer.TOP:
        return $TopDeck
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

    var source_cards = source.cards()
    var destination_cards = destination.cards()
    var relevant_card = source_cards.pop_card(source_index)

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
    return relevant_card


func draw_cards(player: StringName, card_count: int = 1) -> void:
    # TODO Deal with hand limit, and reshuffling the discard (if no
    # discard exists, abort draw)
    var opts = {}
    if player == CardPlayer.TOP:
        opts["custom_displayed_card"] = func (): return HiddenCardDisplay.instantiate()

    var deck = get_deck(player)
    var hand = get_hand(player)
    for i in range(card_count):
        await move_card(deck, hand, opts)


func play_card(player: StringName, card_type: CardType) -> void:
    if not card_type.can_play(self, player):
        push_warning("Attempted to play card %s that cannot be played" % card_type)
        return
    var stats = get_stats(player)
    var hand = get_hand(player)
    var field = card_type.get_destination_strip(self, player)
    var hand_index = hand.cards().find_card(card_type)
    if hand_index == null:
        push_warning("Cannot play card %s because it is not in hand" % card_type)
        return

    # Update stat and animate
    var star_cost = card_type.get_star_cost()
    stats.evil_points -= star_cost
    play_animation_for_stat_change(stats.get_evil_points_node(), - star_cost)

    var new_card = await move_card(hand, field, {
        "source_index": hand_index,
        "destination_transform": DestinationTransform.instantiate_card(player),
    })
    await new_card.on_play(self)


func _on_bottom_hand_card_added(card_node):
    card_node.card_clicked.connect(_on_hand_card_node_card_clicked.bind(card_node))


func _on_play_strip_card_added(card_node):
    card_node.card_clicked.connect(_on_played_card_node_card_clicked.bind(card_node))


func _on_hand_card_node_card_clicked(card_node) -> void:
    var card_type = card_node.card_type
    var card_row = popup_display_card([card_type], {
        "margin_below": 64.0,
    })

    var play_button = Button.new()
    if card_type.can_play(self, CardPlayer.BOTTOM):
        play_button.text = "Play"
        play_button.pressed.connect(func():
            play_card(CardPlayer.BOTTOM, card_type)
            card_row.queue_free())
    else:
        play_button.text = "(Can't afford)"
        play_button.disabled = true
    card_row.append_button(play_button)


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
func popup_display_card(cards: Array, opts = {}) -> Node2D:
    var margin_below = opts.get("margin_below", null)
    var margin_above = opts.get("margin_above", null)

    var viewport_size = get_viewport().get_visible_rect()
    var card_row = ScrollableCardRow.instantiate()
    card_row.card_display_scene = PlayingCardDisplay
    if margin_below != null:
        card_row.margin_below = margin_below
    if margin_above != null:
        card_row.margin_above = margin_above
    $UILayer.add_child(card_row)
    card_row.cards().replace_cards(cards)
    card_row.position = Vector2(0, viewport_size.size.y / 2)
    return card_row


func _on_bottom_hand_cards_modified():
    $BottomStats.on_hand_size_updated($BottomHand.cards().card_count())


func _on_top_hand_cards_modified():
    $TopStats.on_hand_size_updated($TopHand.cards().card_count())


func play_animation_for_stat_change(stat_node: Node2D, delta: int) -> void:
    var animation = NumberAnimation.instantiate()
    animation.position = $AnimationLayer.to_local(stat_node.global_position)
    animation.amount = delta
    $AnimationLayer.add_child(animation)
    await animation.animation_finished
