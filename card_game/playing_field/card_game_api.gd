class_name CardGameApi
extends Node

# Helpers built on top of the PlayingField API.

const CardMovingAnimation = preload("res://card_game/playing_field/animation/card_moving_animation.tscn")
const HiddenCardDisplay = preload("res://card_game/playing_card/hidden_card_display/hidden_card_display.tscn")
const DeckCardDisplay = preload("res://card_game/playing_card/deck_card_display/deck_card_display.tscn")
const NumberAnimation = preload("res://card_game/playing_field/animation/number_animation.tscn")
const InputBlockAnimation = preload("res://card_game/playing_field/animation/input_block_animation.gd")
const NullMinion = preload("res://card_game/playing_card/cards/null_minion.gd")


class CardPosition:
    var card_strip
    var index: int

    func _init(card_strip, index: int):
        self.card_strip = card_strip
        self.index = index


static func find_card_on_field(playing_field, card: Card):
    for strip in playing_field.field_strips():
        var cards = strip.cards()
        for i in range(cards.card_count()):
            if card == cards.peek_card(i):
                return CardPosition.new(strip, i)
    return null


static func find_card_node(playing_field, card: Card):
    var position = find_card_on_field(playing_field, card)
    if position == null:
        return null
    return position.card_strip.get_card_node(position.index)


static func draw_cards(playing_field, player: StringName, card_count: int = 1) -> void:
    var opts = {}
    if player == CardPlayer.TOP:
        opts["custom_displayed_card"] = func (): return HiddenCardDisplay.instantiate()

    var deck = playing_field.get_deck(player)
    var hand = playing_field.get_hand(player)
    var hand_limit = StatsCalculator.get_hand_limit(playing_field, player)
    for i in range(card_count):
        # Don't draw if we're at our hand limit.
        if hand.cards().card_count() >= hand_limit:
            break
        # If we're out of cards, re-shuffle the discard pile.
        if deck.cards().card_count() == 0:
            await reshuffle_discard_pile(playing_field, player)
        # If we're still out of cards, abort the draw.
        if deck.cards().card_count() == 0:
            break
        # Else, draw.
        await playing_field.move_card(deck, hand, opts)


static func reshuffle_discard_pile(playing_field, player: StringName) -> void:
    var deck = playing_field.get_deck(player)
    var discard_pile = playing_field.get_discard_pile(player)
    if discard_pile.cards().card_count() == 0:
        return  # Nothing to do
    var animation_layer = playing_field.get_animation_layer()

    var deck_array = deck.cards().card_array()
    var discard_array = discard_pile.cards().card_array()

    discard_pile.cards().clear_cards()
    playing_field.emit_cards_moved()

    # Animate the deck moving
    var animation = CardMovingAnimation.instantiate()
    animation_layer.add_child(animation)
    animation.replace_displayed_card(DeckCardDisplay.instantiate())
    animation.set_card(NullMinion.new())
    animation.animation_time = 0.125
    await animation.animate(discard_pile.position, deck.position)
    animation.queue_free()

    deck_array.append_array(discard_array)
    deck_array.shuffle()
    deck.cards().replace_cards(deck_array)
    playing_field.emit_cards_moved()


static func play_card(playing_field, player: StringName, card_type: CardType) -> void:
    if not card_type.can_play(playing_field, player):
        push_warning("Attempted to play card %s that cannot be played" % card_type)
        return
    var stats = playing_field.get_stats(player)
    var hand = playing_field.get_hand(player)
    var field = card_type.get_destination_strip(playing_field, player)
    var hand_index = hand.cards().find_card(card_type)
    if hand_index == null:
        push_warning("Cannot play card %s because it is not in hand" % card_type)
        return

    # Update stat and animate
    var star_cost = card_type.get_star_cost()
    stats.evil_points -= star_cost
    play_animation_for_stat_change(playing_field, stats.get_evil_points_node(), - star_cost)

    var new_card = await playing_field.move_card(hand, field, {
        "source_index": hand_index,
        "destination_transform": DestinationTransform.instantiate_card(player),
    })
    await new_card.on_play(playing_field)


static func play_animation_for_stat_change(playing_field, stat_node: Node2D, delta: int) -> void:
    var animation_layer = playing_field.get_animation_layer()
    var animation = NumberAnimation.instantiate()
    animation.position = animation_layer.to_local(stat_node.global_position)
    animation.amount = delta
    animation_layer.add_child(animation)
    await animation.animation_finished


static func highlight_card(playing_field, card: Card) -> void:
    var card_node = find_card_node(playing_field, card)
    if card_node == null:
        push_warning("Cannot highlight card %s because it is not in play" % card)
        return
    var input_block = InputBlockAnimation.new()
    playing_field.get_animation_layer().add_child(input_block)
    await card_node.play_highlight_animation()
    input_block.free()


static func destroy_card(playing_field, card: Card) -> void:
    var card_pos = find_card_on_field(playing_field, card)
    if card_pos == null:
        push_warning("Cannot destroy card %s because it is not in play" % card)
        return
    var discard_pile = playing_field.get_discard_pile(card.original_owner)
    await playing_field.move_card(card_pos.card_strip, discard_pile, {
        "source_index": card_pos.index,
        "destination_transform": DestinationTransform.strip_to_card_type,
    })
