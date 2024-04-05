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


# Accepted opts:
#
# * is_token (Boolean) - true if this is a temporary token
func _init(card_type: CardType, owner: StringName, opts = {}) -> void:
    self.card_type = card_type
    self.owner = owner
    self.original_owner = owner
    self.is_token = opts.get("is_token", false)
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

    # Token icon
    if is_token:
        icons.append(CardIcon.Frame.TOKEN)

    # Archetype overrides
    if card_type is MinionCardType:
        var archetype_overrides = metadata[CardMeta.ARCHETYPE_OVERRIDES]
        if archetype_overrides != null:
            icons.append_array(archetype_overrides.map(Archetype.to_icon_index))

    return icons


func has_archetype(playing_field, archetype: int) -> bool:
    if not (card_type is MinionCardType):
        push_warning("Attempt to check Archetype of non-Minion card %s" % self)
        return false
    var archetypes = card_type.get_archetypes(playing_field, self)
    return archetype in archetypes
