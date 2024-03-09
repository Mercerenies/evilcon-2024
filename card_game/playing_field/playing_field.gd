extends Node2D

const CardMovingAnimation = preload("res://card_game/playing_field/animation/card_moving_animation.tscn")
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


func get_minion_row(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomMinionStrip
    elif player == CardPlayer.TOP:
        return $TopMinionStrip
    else:
        push_error("Bad card player %s" % player)
        return null


func get_effect_row(player: StringName):
    if player == CardPlayer.BOTTOM:
        return $BottomEffectStrip
    elif player == CardPlayer.TOP:
        return $TopEffectStrip
    else:
        push_error("Bad card player %s" % player)
        return null


# Moves a card from one node to another. The referenced nodes must
# have a method called cards() which returns a CardContainer.
func move_card(source, destination, opts = {}) -> void:
    var source_index = opts.get("source_index", -1)
    var animation_scale = opts.get("scale", Vector2(0.25, 0.25))
    var custom_displayed_card = opts.get("custom_displayed_card", null)

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

    destination_cards.push_card(relevant_card)


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


func _on_bottom_hand_card_added(card_node):
    card_node.card_clicked.connect(_on_hand_card_node_card_clicked.bind(card_node))


func _on_hand_card_node_card_clicked(card_node):
    var viewport_size = get_viewport().get_visible_rect()
    var card_type = card_node.get_card()
    var card_row = ScrollableCardRow.instantiate()
    card_row.card_display_scene = PlayingCardDisplay
    card_row.margin_below = 64
    $UILayer.add_child(card_row)
    card_row.cards().replace_cards([card_type])
    card_row.position = Vector2(0, viewport_size.size.y / 2)

    # TODO Disable this button if we can't afford to play
    var play_button = Button.new()
    play_button.text = "Play"
    card_row.append_button(play_button)
