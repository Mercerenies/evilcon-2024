class_name Card
extends RefCounted


var card_type: CardType
var owner: StringName
var original_owner: StringName


func _init(card_type: CardType, owner: StringName) -> void:
    self.card_type = card_type
    self.owner = owner
    self.original_owner = owner


func on_play(playing_field) -> void:
    await card_type.on_play(playing_field, self)
