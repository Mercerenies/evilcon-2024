class_name StatsCalculator
extends Node

const BASE_HAND_LIMIT := 5
const BASE_CARDS_PER_TURN := 3
const MIN_EP_PER_TURN := 2
const MAX_EP_PER_TURN := 8

static func get_hand_limit(playing_field, player: StringName) -> int:
    return (
        CardGameApi.broadcast_to_cards(playing_field, "get_hand_limit_modifier", [player])
        .reduce(Operator.plus, BASE_HAND_LIMIT)
    )


static func get_evil_points_per_turn(playing_field, player: StringName) -> int:
    var base_ep_per_turn = clampi(playing_field.turn_number + MIN_EP_PER_TURN, MIN_EP_PER_TURN, MAX_EP_PER_TURN)
    return (
        CardGameApi.broadcast_to_cards(playing_field, "get_ep_per_turn_modifier", [player])
        .reduce(Operator.plus, base_ep_per_turn)
    )


static func get_cards_per_turn(playing_field, player: StringName) -> int:
    return (
        CardGameApi.broadcast_to_cards(playing_field, "get_cards_per_turn_modifier", [player])
        .reduce(Operator.plus, BASE_CARDS_PER_TURN)
    )
