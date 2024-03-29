class_name Card
extends RefCounted


var card_type: CardType
var owner: StringName
var original_owner: StringName

# `metadata` is a mutable dictionary provided to all cards. This
# dictionary starts out empty and is used to store any stateful
# properties of the card. This includes Level and Morale for minions,
# and turn counters for certain effects.
#
# This dictionary's keys should come from the constants in
# CardMeta.gd, for organization purposes.
var metadata: Dictionary


func _init(card_type: CardType, owner: StringName) -> void:
    self.card_type = card_type
    self.owner = owner
    self.original_owner = owner
    self.metadata = {}
    self.card_type.on_instantiate(self)


func on_play(playing_field) -> void:
    await card_type.on_play(playing_field, self)


func get_overlay_text(playing_field) -> String:
    return card_type.get_overlay_text(playing_field, self)
