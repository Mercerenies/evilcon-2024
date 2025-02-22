class_name CardGameApi
extends Node

# Helpers built on top of the PlayingField API.

const CardMovingAnimation = preload("res://card_game/playing_field/animation/card_moving/card_moving_animation.tscn")
const HiddenCardDisplay = preload("res://card_game/playing_card/hidden_card_display/hidden_card_display.tscn")
const DeckCardDisplay = preload("res://card_game/playing_card/deck_card_display/deck_card_display.tscn")
const InputBlockAnimation = preload("res://card_game/playing_field/animation/input_block_animation.gd")
const PuffOfSmokeAnimation = preload("res://card_game/playing_field/animation/puff_of_smoke/puff_of_smoke_animation.tscn")
const MusicalNoteAnimation = preload("res://card_game/playing_field/animation/musical_note/musical_note_animation.tscn")
const NullMinion = preload("res://card_game/playing_card/cards/null_minion.gd")

class CardPosition:
    var card_strip
    var index: int

    func _init(card_strip, index: int):
        self.card_strip = card_strip
        self.index = index


# Moves a card from one node to another.
#
# The source and destination nodes must be Node2Ds and must have a
# method called cards() which returns the appropriate CardContainer.
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
static func move_card(playing_field, source, destination, opts = {}):
    var source_index = opts.get("source_index", -1)
    var destination_transform = opts.get("destination_transform", null)

    # TODO Consider finding the exact position within the row, if one
    # exists. :)

    var source_cards = source.cards()
    var destination_cards = destination.cards()
    var relevant_card = source_cards.pop_card(source_index)
    playing_field.emit_cards_moved()

    # Animate the card moving
    await playing_field.animate_card_moving(source, destination, relevant_card, opts)

    if destination_transform != null:
        relevant_card = destination_transform.call(relevant_card)
    destination_cards.push_card(relevant_card)
    playing_field.emit_cards_moved()
    return relevant_card


static func field_strips(playing_field) -> Array:
    return [
        playing_field.get_minion_strip(CardPlayer.BOTTOM),
        playing_field.get_minion_strip(CardPlayer.TOP),
        playing_field.get_effect_strip(CardPlayer.BOTTOM),
        playing_field.get_effect_strip(CardPlayer.TOP),
    ]


static func find_card_on_field(playing_field, card: Card):
    for strip in field_strips(playing_field):
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


# Returns the turn player's cards first, then the opponent's cards.
# This is the order that effects generally evaluate in. For each
# player, returns minions first then effects.
static func get_cards_in_play(playing_field) -> Array:
    var turn_player = playing_field.turn_player
    var cards = []
    cards.append_array(playing_field.get_minion_strip(turn_player).cards().card_array())
    cards.append_array(playing_field.get_effect_strip(turn_player).cards().card_array())
    cards.append_array(playing_field.get_minion_strip(CardPlayer.other(turn_player)).cards().card_array())
    cards.append_array(playing_field.get_effect_strip(CardPlayer.other(turn_player)).cards().card_array())
    return cards


static func get_minions_in_play(playing_field) -> Array:
    var turn_player = playing_field.turn_player
    var cards = []
    cards.append_array(playing_field.get_minion_strip(turn_player).cards().card_array())
    cards.append_array(playing_field.get_minion_strip(CardPlayer.other(turn_player)).cards().card_array())
    return cards


static func get_effects_in_play(playing_field) -> Array:
    var turn_player = playing_field.turn_player
    var cards = []
    cards.append_array(playing_field.get_effect_strip(turn_player).cards().card_array())
    cards.append_array(playing_field.get_effect_strip(CardPlayer.other(turn_player)).cards().card_array())
    return cards


# method can be either a string or a callable. If it's a string, it's
# called as a method on each card type. In either case, the first two
# arguments are the playing field and the card itself. The result of
# the callable or method will be `await`ed.
static func broadcast_to_cards_async(playing_field, method, binds = []) -> Array:
    # Normalize method and binds to a single callable that encompasses
    # all cases. We have to do this in several cases since I can't
    # just forward arguments with (*args, **kwargs) like I would in
    # Python.
    if method is String:
        var method_name = method  # Anchor to variable so we can close around it.
        if len(binds) > 0:
            method = func broadcast_lambda_with_bindings(playing_field_, card):
                return await card.card_type.callv(method_name, [playing_field_, card] + binds)
        else:
            method = func broadcast_lambda(playing_field_, card):
                return await card.card_type.call(method_name, playing_field_, card)
    elif len(binds) > 0:
        method = method.bindv(binds)

    var results = []
    var all_cards = get_cards_in_play(playing_field)
    for card in all_cards:
        var result = await method.call(playing_field, card)
        results.append(result)
    return results


# Same as broadcast_to_cards_async but forbids `await`ing.
static func broadcast_to_cards(playing_field, method, binds = []) -> Array:
    # Normalize method and binds to a single callable that encompasses
    # all cases. We have to do this in several cases since I can't
    # just forward arguments with (*args, **kwargs) like I would in
    # Python.
    if method is String:
        var method_name = method  # Anchor to variable so we can close around it.
        if len(binds) > 0:
            method = func broadcast_lambda_with_bindings(playing_field_, card):
                return card.card_type.callv(method_name, [playing_field_, card] + binds)
        else:
            method = func broadcast_lambda(playing_field_, card):
                return card.card_type.call(method_name, playing_field_, card)
    elif len(binds) > 0:
        method = method.bindv(binds)

    var results = []
    var all_cards = get_cards_in_play(playing_field)
    for card in all_cards:
        var result = method.call(playing_field, card)
        results.append(result)
    return results



static func play_smoke_animation(playing_field, target_node) -> void:
    var input_block = InputBlockAnimation.new()

    await playing_field.with_animation(func(animation_layer):
        animation_layer.add_child(input_block)
        var animation_node = PuffOfSmokeAnimation.instantiate()
        animation_layer.add_child(animation_node)
        animation_node.position = animation_layer.to_local(target_node.global_position)
        await animation_node.tree_exited)

    input_block.free()


static func play_musical_note_animation(playing_field, target_node) -> void:
    var input_block = InputBlockAnimation.new()

    await playing_field.with_animation(func(animation_layer):
        animation_layer.add_child(input_block)
        var animation_node = MusicalNoteAnimation.instantiate()
        animation_layer.add_child(animation_node)
        animation_node.position = animation_layer.to_local(target_node.global_position)
        await animation_node.main_animation_completed)

    input_block.free()


static func draw_cards(playing_field, player: StringName, card_count: int = 1) -> void:
    var opts = {}
    if playing_field.hand_cards_are_hidden(player):
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
        await move_card(playing_field, deck, hand, opts)


static func draw_specific_card(playing_field, player: StringName, card_type: CardType) -> void:
    var deck = playing_field.get_deck(player)
    var hand = playing_field.get_hand(player)
    var deck_index = deck.cards().find_card(card_type)
    if deck_index == null:
        push_warning("Cannot draw card %s from deck because it is not in deck" % card_type)
        return
    var opts = {
        "source_index": deck_index,
    }
    if playing_field.hand_cards_are_hidden(player):
        opts["custom_displayed_card"] = func (): return HiddenCardDisplay.instantiate()
    await move_card(playing_field, deck, hand, opts)


static func reshuffle_discard_pile(playing_field, player: StringName) -> void:
    var deck = playing_field.get_deck(player)
    var discard_pile = playing_field.get_discard_pile(player)
    if discard_pile.cards().card_count() == 0:
        return  # Nothing to do

    var deck_array = deck.cards().card_array()
    var discard_array = discard_pile.cards().card_array()

    discard_pile.cards().clear_cards()
    playing_field.emit_cards_moved()

    # Animate the deck moving
    await playing_field.with_animation(func(animation_layer):
        var animation = CardMovingAnimation.instantiate()
        animation_layer.add_child(animation)
        animation.replace_displayed_card(DeckCardDisplay.instantiate())
        animation.set_card(NullMinion.new())
        animation.animation_time = 0.125
        await animation.animate(discard_pile.position, deck.position, {
            "start_angle": discard_pile.global_rotation,
            "end_angle": deck.global_rotation,
        })
        animation.queue_free())

    deck_array.append_array(discard_array)
    deck_array.shuffle()
    deck.cards().replace_cards(deck_array)
    playing_field.emit_cards_moved()


static func play_card_from_hand(playing_field, player: StringName, card_type: CardType):
    if not card_type.can_play(playing_field, player):
        push_warning("Attempted to play card %s that cannot be played" % card_type)
        return
    var hand = playing_field.get_hand(player)
    var field = card_type.get_destination_strip(playing_field, player)
    var hand_index = hand.cards().find_card(card_type)
    if hand_index == null:
        push_warning("Cannot play card %s from hand because it is not in hand" % card_type)
        return
    await Stats.add_evil_points(playing_field, player, - card_type.get_star_cost())
    var new_card = await move_card(playing_field, hand, field, {
        "source_index": hand_index,
        "destination_transform": DestinationTransform.instantiate_card(player),
    })
    await new_card.on_play(playing_field)
    return new_card


# Move from discard pile to field.
static func resurrect_card(playing_field, player: StringName, card_type: CardType):
    var discard_pile = playing_field.get_discard_pile(player)
    var field = card_type.get_destination_strip(playing_field, player)
    var discard_index = discard_pile.cards().find_card_reversed(card_type)
    if discard_index == null:
        push_warning("Cannot resurrect card %s because it is not in discard pile" % card_type)
        return
    var new_card = await move_card(playing_field, discard_pile, field, {
        "source_index": discard_index,
        "destination_transform": DestinationTransform.instantiate_card(player),
    })
    await new_card.on_play(playing_field)
    return new_card


# Move from deck to field.
static func play_card_from_deck(playing_field, player: StringName, card_type: CardType):
    var deck = playing_field.get_deck(player)
    var field = card_type.get_destination_strip(playing_field, player)
    var deck_index = deck.cards().find_card_reversed(card_type)
    if deck_index == null:
        push_warning("Cannot play card %s from deck because it is not in deck" % card_type)
        return
    var new_card = await move_card(playing_field, deck, field, {
        "source_index": deck_index,
        "destination_transform": DestinationTransform.instantiate_card(player),
    })
    await new_card.on_play(playing_field)
    return new_card


# Put a card in the field, as though from nowhere. This is usually
# preceded by a custom animation to create the card object, such as
# that seen in the Mystery Box effect.
#
# Optional arguments are as follows:
#
# * is_token (boolean) - Whether or not the new card is a token.
# * Defaults to true.
static func play_card_from_nowhere(playing_field, player: StringName, card_type: CardType, origin: Vector2, opts = {}):
    var is_token = opts.get("is_token", true)
    var field = card_type.get_destination_strip(playing_field, player)

    await playing_field.with_animation(func(animation_layer):
        var animation = CardMovingAnimation.instantiate()
        animation_layer.add_child(animation)
        animation.scale = Vector2(0.25, 0.25)
        animation.set_card(card_type)
        await animation.animate(origin, field.position, {
            "start_angle": 0.0,
            "end_angle": field.global_rotation,
        })
        animation.queue_free())

    var new_card = Card.new(card_type, player)
    if is_token:
        new_card.metadata[CardMeta.IS_TOKEN] = true
    field.cards().push_card(new_card)
    await new_card.on_play(playing_field)
    playing_field.emit_cards_moved()

    return new_card


static func highlight_card(playing_field, card: Card) -> void:
    await playing_field.with_animation(func(animation_layer):
        var card_node = find_card_node(playing_field, card)
        if card_node == null:
            push_warning("Cannot highlight card %s because it is not in play" % card)
            return
        var input_block = InputBlockAnimation.new()
        animation_layer.add_child(input_block)
        await card_node.play_highlight_animation()
        input_block.free())


# Rotation animation: Used for Vitamin Capsule and Ultimate Fusion.
static func rotate_card(playing_field, card: Card) -> void:
    await playing_field.with_animation(func(animation_layer):
        var card_node = find_card_node(playing_field, card)
        if card_node == null:
            push_warning("Cannot rotate card %s because it is not in play" % card)
            return
        var input_block = InputBlockAnimation.new()
        animation_layer.add_child(input_block)
        await card_node.play_rotate_animation()
        input_block.free())


static func destroy_card(playing_field, card: Card) -> void:
    if card.is_token() or card.is_doomed():
        # Tokens and doomed cards are exiled instead
        await exile_card(playing_field, card)
        return

    var card_pos = find_card_on_field(playing_field, card)
    if card_pos == null:
        push_warning("Cannot destroy card %s because it is not in play" % card)
        return
    var discard_pile = playing_field.get_discard_pile(card.original_owner)
    await move_card(playing_field, card_pos.card_strip, discard_pile, {
        "source_index": card_pos.index,
        "destination_transform": DestinationTransform.strip_to_card_type,
    })


# Move from hand to discard pile
static func discard_card(playing_field, player: StringName, card_type: CardType) -> void:
    var hand = playing_field.get_hand(player)
    var discard_pile = playing_field.get_discard_pile(player)
    var hand_index = hand.cards().find_card(card_type)
    if hand_index == null:
        push_warning("Cannot discard card %s from hand because it is not in hand" % card_type)
        return
    await move_card(playing_field, hand, discard_pile, {
        "source_index": hand_index,
    })


# Move from discard pile to deck
static func move_card_from_discard_to_deck(playing_field, player: StringName, card_type: CardType) -> void:
    var discard_pile = playing_field.get_discard_pile(player)
    var deck = playing_field.get_deck(player)
    var discard_pile_index = discard_pile.cards().find_card(card_type)
    if discard_pile_index == null:
        push_warning("Cannot move card %s from discard pile to deck, because it is not in discard pile" % card_type)
        return
    await move_card(playing_field, discard_pile, deck, {
        "source_index": discard_pile_index,
    })


static func create_card(playing_field, player: StringName, card_type: CardType, is_token: bool = true) -> Card:
    var new_card = Card.new(card_type, player)
    if is_token:
        new_card.metadata[CardMeta.IS_TOKEN] = true
    var field = card_type.get_destination_strip(playing_field, player)
    field.cards().push_card(new_card)
    playing_field.emit_cards_moved()

    # Now animate the creation
    await playing_field.with_animation(func(_animation_layer):
        var card_node = find_card_node(playing_field, new_card)
        card_node.play_fade_in_animation()
        await play_smoke_animation(playing_field, card_node))

    await new_card.card_type.on_enter_ownership(playing_field, new_card)
    return new_card


# Copies a card which is already in play. All metadata on that card is
# copied, but the new card will always be a token if is_token is true
# (the default value).
static func copy_card(playing_field, player: StringName, original_card: Card, is_token: bool = true) -> Card:
    var new_card = Card.new(original_card.card_type, player)
    for key in original_card.metadata.keys():
        new_card.metadata[key] = original_card.metadata[key]
    if is_token:
        new_card.metadata[CardMeta.IS_TOKEN] = true
    var field = original_card.card_type.get_destination_strip(playing_field, player)
    field.cards().push_card(new_card)
    playing_field.emit_cards_moved()

    # Now animate the creation
    await playing_field.with_animation(func(_animation_layer):
        var card_node = find_card_node(playing_field, new_card)
        card_node.play_fade_in_animation()
        await play_smoke_animation(playing_field, card_node))

    await new_card.card_type.on_enter_ownership(playing_field, new_card)
    return new_card


static func exile_card(playing_field, card: Card) -> void:
    var card_pos = find_card_on_field(playing_field, card)
    if card_pos == null:
        push_warning("Cannot exile card %s because it is not in play" % card)
        return

    # Now animate the exile
    await playing_field.with_animation(func(_animation_layer):
        var card_node = find_card_node(playing_field, card)
        card_node.play_fade_out_animation()
        await play_smoke_animation(playing_field, card_node))

    card_pos.card_strip.cards().pop_card(card_pos.index)
    playing_field.emit_cards_moved()
