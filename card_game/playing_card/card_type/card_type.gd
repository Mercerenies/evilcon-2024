class_name CardType
extends RefCounted

const EffectTextFont = preload("res://fonts/Raleway-Regular.ttf")
const FlavorTextFont = preload("res://fonts/Raleway-Italic.ttf")
const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")


func get_id() -> int:
    # Unique ID, must be unique among CardType subclasses.
    push_warning("Forgot to override get_id!")
    return -1


func get_title() -> String:
    push_warning("Forgot to override get_title!")
    return ""


func get_text() -> String:
    push_warning("Forgot to override get_text!")
    return ""


func get_picture_index() -> int:
    push_warning("Forgot to override get_picture_index!")
    return 0


func get_rarity() -> int:
    push_warning("Forgot to override get_rarity!")
    return 0


func get_destination_strip(_playing_field, _owner: StringName):
    push_warning("Forgot to override get_destination_strip!")
    return null


func get_icon_row() -> Array:
    if is_limited():
        return [CardIcon.Frame.LIMITED]
    else:
        return []


func get_star_cost() -> int:
    push_warning("Forgot to override get_star_cost!")
    return 0


func get_stats_text() -> String:
    push_warning("Forgot to override get_stats_text!")
    return ""


func is_text_flavor() -> bool:
    return false


func is_limited() -> bool:
    return false


func get_archetypes_row_text() -> String:
    return ""


func can_play(playing_field, owner: StringName) -> bool:
    # Default implementation simply checks EP, which should be
    # sufficient in most, if not all, cases.
    var card_cost = get_star_cost()
    var user_evil_points = playing_field.get_stats(owner).evil_points
    return user_evil_points >= card_cost


func on_play(playing_field, card) -> void:
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_play_broadcasted", [card])


func on_play_broadcasted(_playing_field, _this_card, _played_card) -> void:
    pass


func on_instantiate(_card) -> void:
    # This optional method is called when the card is first
    # instantiated. This usually happens right before the card is put
    # into play, but that should not be assumed. Note that this method
    # does NOT have access to a PlayingField, as it should only set up
    # properties intrinsic to the card, not calculate things that
    # depend on the state of the board. Use on_play for global effects
    # that should happen when the card is put onto the playing field.
    pass


func get_overlay_text(_playing_field, _card) -> String:
    # Returns the overlay text to show on the card while it's in play,
    # if any. Any game action which has the potential to update the
    # result of this method should emit PlayingField.cards_moved.
    return ""


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    # Called when the source_card is about to affect the target_card
    # in some way. This method should return true if the source card
    # is permitted to affect the target card (which is usually the
    # case), or false if something blocks the effect.
    #
    # If the `silently` argument is false, this method is permitted to
    # be a coroutine (i.e. to "await"), in order to play animations.
    # If `silently` is true, this method must not perform any
    # animations.
    #
    # The default implementation behaves like
    # CardGameApi.broadcast_to_cards (resp.
    # CardGameApi.broadcast_to_cards_async) but will short-circuit
    # when it finds the first card that blocks the influence.
    # Additionally, the default implementation respects
    # CardMeta.HAS_SPECIAL_IMMUNITY.

    # NOTE: If silently = true, these `await` calls SHOULD do nothing.

    # Special immunity check
    if target_card.metadata.get(CardMeta.HAS_SPECIAL_IMMUNITY, false):
        if not await CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently):
            return false

    # Broadcast check
    for card in CardGameApi.get_cards_in_play(playing_field):
        if not card.card_type.do_broadcasted_influence_check(playing_field, card, target_card, source_card, silently):
            return false

    # Effect is permitted
    return true


func do_broadcasted_influence_check(_playing_field, _card, _target_card, _source_card, _silently: bool) -> bool:
    # Called when the source_card is about to affect the target_card,
    # giving a third party (the card argument) a chance to intervene.
    # If it is always true that card == target_card, then you should
    # be overriding do_influence_check instead.
    return true


func do_passive_hero_check(_playing_field, _card, _hero_card) -> bool:
    # Called when a Hero card indicated by `hero_card` is about to
    # perform its effect. This method should return true (the default)
    # if the card is permitted to proceed as planned, and false if
    # this card is blocking the hero card. This method may `await`.
    #
    # This method should only trigger for cards that block Hero cards
    # passively and do not discard themselves when blocking. Use
    # do_active_hero_check for cards which must tribute themselves to
    # block.
    return true


func do_active_hero_check(_playing_field, _card, _hero_card) -> bool:
    # Called when a Hero card indicated by `hero_card` is about to
    # perform its effect. This method should return true (the default)
    # if the card is permitted to proceed as planned, and false if
    # this card is blocking the hero card. This method may `await`.
    #
    # This method should only trigger for cards that block Hero cards
    # by sacrificing oneself or something else. Use
    # do_passive_hero_check for cards which block Hero cards for free.
    return true


func do_attack_phase_check(_playing_field, _this_card, _attacking_card) -> bool:
    # Called when the attacking_card is about to perform its Attack
    # Phase. This method should return true if the attacking_card is
    # permitted to proceed as planned, and false if the attacking_card
    # should skip its Attack Phase.
    #
    # This method is permitted to `await`.
    return true


func do_morale_phase_check(_playing_field, _this_card, _performing_card) -> bool:
    # Called when the performing_card is about to perform its Morale
    # Phase. This method should return true if the performing_card is
    # permitted to proceed as planned, and false if the
    # performing_card should skip its Morale Phase.
    #
    # This method is permitted to `await`.
    return true


func augment_attack_damage(_playing_field, _this_card, _attacking_card) -> int:
    # Called when attacking_card is about to perform a standard attack
    # during its Attack Phase (as opposed to cards which have a custom
    # action during their Attack Phase). This method is only called if
    # do_attack_phase_check already passed for the particular
    # attacking card. Should return an amount to add or subtract
    # (temporarily) from the attacker's Level during damage
    # calculation. A positive return value will increase the damage
    # dealt, while a negative return value will decrease the damage
    # dealt. The damage dealt will be capped at zero and will not go
    # into the negative as a result of these augmentations.
    #
    # This method is permitted to `await`.
    return 0


func on_draw_phase(_playing_field, _card) -> void:
    # NOTE: Does not broadcast, since the phase itself is already
    # being broadcasted. If we change this behavior, MAKE SURE to
    # check all subclasses for missing supers.
    pass


func on_attack_phase(_playing_field, _card) -> void:
    # NOTE: Does not broadcast, since the phase itself is already
    # being broadcasted. If we change this behavior, MAKE SURE to
    # check all subclasses for missing supers.
    pass


func on_morale_phase(_playing_field, _card) -> void:
    # NOTE: Does not broadcast, since the phase itself is already
    # being broadcasted. If we change this behavior, MAKE SURE to
    # check all subclasses for missing supers.
    pass


func on_standby_phase(_playing_field, _card) -> void:
    # NOTE: Does not broadcast, since the phase itself is already
    # being broadcasted. If we change this behavior, MAKE SURE to
    # check all subclasses for missing supers.
    pass


func on_end_phase(_playing_field, _card) -> void:
    # NOTE: Does not broadcast, since the phase itself is already
    # being broadcasted. If we change this behavior, MAKE SURE to
    # check all subclasses for missing supers.
    pass


func on_pre_expire_broadcasted(_playing_field, _this_card, _expiring_card) -> void:
    pass


func on_expire_broadcasted(_playing_field, _this_card, _expiring_card) -> void:
    pass


func get_ep_per_turn_modifier(_playing_field, _card, _player: StringName) -> int:
    return 0


func get_hand_limit_modifier(_playing_field, _card, _player: StringName) -> int:
    return 0


func get_cards_per_turn_modifier(_playing_field, _card, _player: StringName) -> int:
    return 0


func is_spiky_broadcasted(_playing_field, _this_card, _candidate_card) -> bool:
    # Broadcasted "Spiky" check for a Minion candidate card. See
    # MinionCardType.is_spiky for details.
    #
    # This method MUST NOT await.
    return false
