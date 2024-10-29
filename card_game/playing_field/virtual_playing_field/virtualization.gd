class_name Virtualization
extends Node

const VirtualPlayingField = preload("res://card_game/playing_field/virtual_playing_field/virtual_playing_field.tscn")


# Given any playing field, constructs a VirtualPlayingField consisting
# of the same cards and game state. If given a VirtualPlayingField,
# this function has the effect of deep-copying the field.
#
# This method does NOT attempt to copy the player agents. The player
# agents on the new field will be the default values (NullAIAgent) and
# must be set manually to the desired values.
static func to_virtual(playing_field):
    var new_field = VirtualPlayingField.instantiate()
    new_field.turn_number = playing_field.turn_number
    new_field.turn_player = playing_field.turn_player
    new_field.event_logger = playing_field.event_logger.deepclone()
    for player in CardPlayer.ALL:
        _copy_cards(playing_field.get_deck(player), new_field.get_deck(player))
        _copy_cards(playing_field.get_discard_pile(player), new_field.get_discard_pile(player))
        _copy_cards(playing_field.get_hand(player), new_field.get_hand(player))
        _copy_cards(playing_field.get_minion_strip(player), new_field.get_minion_strip(player))
        _copy_cards(playing_field.get_effect_strip(player), new_field.get_effect_strip(player))
        new_field.get_stats(player).load_stats_from(playing_field.get_stats(player))
    return new_field


static func _copy_cards(source, destination) -> void:
    var cards = source.cards().card_array().map(func(c): return c.deepclone())
    destination.cards().replace_cards(cards)
