class_name StatsCalculator
extends Node

const BASE_HAND_LIMIT := 5
const BASE_CARDS_PER_TURN := 3
const MIN_EP_PER_TURN := 2
const MAX_EP_PER_TURN := 8

static func get_hand_limit(_playing_field, _player: StringName) -> int:
    return BASE_HAND_LIMIT  # TODO Calculate from cards


static func get_evil_points_per_turn(playing_field, _player: StringName) -> int:
    var base_ep_per_turn = clampi(playing_field.turn_number + MIN_EP_PER_TURN, MIN_EP_PER_TURN, MAX_EP_PER_TURN)
    return base_ep_per_turn  # TODO Calculate from cards


static func get_cards_per_turn(_playing_field, _player: StringName) -> int:
    return BASE_CARDS_PER_TURN  # TODO Calculate from cards
