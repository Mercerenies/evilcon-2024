class_name CardGameApi
extends Node

# Helpers built on top of the PlayingField API.

const HiddenCardDisplay = preload("res://card_game/playing_card/hidden_card_display/hidden_card_display.tscn")
const NumberAnimation = preload("res://card_game/playing_field/animation/number_animation.tscn")
const InputBlockAnimation = preload("res://card_game/playing_field/animation/input_block_animation.gd")

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
    # TODO Deal with hand limit, and reshuffling the discard (if no
    # discard exists, abort draw)
    var opts = {}
    if player == CardPlayer.TOP:
        opts["custom_displayed_card"] = func (): return HiddenCardDisplay.instantiate()

    var deck = playing_field.get_deck(player)
    var hand = playing_field.get_hand(player)
    for i in range(card_count):
        await playing_field.move_card(deck, hand, opts)


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
    if card_node != null:
        var input_block = InputBlockAnimation.new()
        playing_field.get_animation_layer().add_child(input_block)
        await card_node.play_highlight_animation()
        input_block.free()
