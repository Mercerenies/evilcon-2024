class_name Card
extends RefCounted

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")


var card_type: CardType
var owner: StringName
var original_owner: StringName

# A token card is a card that does not belong in a player's deck. A
# token is created from nothing and, when removed from the field for
# any reason, is exiled. That is, a token can never be placed in the
# deck, hand, or discard pile, and any attempts to do so will result
# in exiling the card instead.
var is_token: bool

# `metadata` is a mutable dictionary provided to all cards. This
# dictionary starts out empty and is used to store any stateful
# properties of the card. This includes Level and Morale for minions,
# and turn counters for certain effects.
#
# This dictionary's keys should come from the constants in
# CardMeta.gd, for organization purposes.
var metadata: Dictionary


func _init(card_type: CardType, owner: StringName, is_token: bool = false) -> void:
    self.card_type = card_type
    self.owner = owner
    self.original_owner = owner
    self.is_token = is_token
    self.metadata = {}
    self.card_type.on_instantiate(self)


func on_play(playing_field) -> void:
    await card_type.on_play(playing_field, self)


func get_overlay_text(playing_field) -> String:
    return card_type.get_overlay_text(playing_field, self)


func get_overlay_icons(_playing_field) -> Array:
    # NOTE: This method does NOT delegate to the card_type. Instead,
    # the overlay icons are entirely determined by modifiers to the
    # card itself, in a uniform way.
    var icons = []
    if is_token:
        icons.append(CardIcon.Frame.TOKEN)
    return icons
