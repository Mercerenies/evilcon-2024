class_name Card
extends RefCounted

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")


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


# opts must be empty; reserved for future use.
func _init(card_type: CardType, owner: StringName, _opts = {}) -> void:
    self.card_type = card_type
    self.owner = owner
    self.original_owner = owner
    self.metadata = {}
    self.card_type.on_instantiate(self)


func on_play(playing_field) -> void:
    await card_type.on_play(playing_field, self)


func get_overlay_text(playing_field) -> String:
    return card_type.get_overlay_text(playing_field, self)


func is_token() -> bool:
    return metadata.get(CardMeta.IS_TOKEN, false)


func is_doomed() -> bool:
    return metadata.get(CardMeta.IS_DOOMED, false)


func get_overlay_icons(_playing_field) -> Array:
    # NOTE: This method does NOT delegate to the card_type. Instead,
    # the overlay icons are entirely determined by modifiers to the
    # card itself, in a uniform way.
    var icons = []

    # Token icon
    if is_token():
        icons.append(CardIcon.Frame.TOKEN)

    # Doomed icon
    if is_doomed():
        icons.append(CardIcon.Frame.DOOMED)

    # Immunity icon
    if metadata.get(CardMeta.HAS_SPECIAL_IMMUNITY, false):
        icons.append(CardIcon.Frame.IMMUNITY)

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
