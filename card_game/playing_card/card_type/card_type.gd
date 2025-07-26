class_name CardType
extends RefCounted

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
    if owner != playing_field.turn_player:
        return false
    var card_cost = get_star_cost()
    var user_evil_points = playing_field.get_stats(owner).evil_points
    return user_evil_points >= card_cost


func on_play(playing_field, card) -> void:
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_play_broadcasted", [card])
    await on_enter_ownership(playing_field, card)


func on_play_broadcasted(_playing_field, _this_card, _played_card) -> void:
    pass


# Called when the card adopts an owner. This method is called anytime
# the card takes on an owner (either for the first time or sometime
# after), whether that's because the card was just played (on_play),
# because the card was just created (as a token), or because the card
# moved owners due to Brainwashing Ray.
#
# This method MAY await. Subclass implementations MUST call super.
func on_enter_ownership(playing_field, card) -> void:
    await CardGameApi.broadcast_to_cards_async(playing_field, "on_enter_ownership_broadcasted", [card])


# Called (broadcasted on all cards) just after the target card changes
# alignment due to an effect like Brainwashing Ray.
func on_enter_ownership_broadcasted(_playing_field, _this_card, _brainwashed_card) -> void:
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
    # If the `silently` argument is false, this method to play
    # animations. If `silently` is true, this method must not perform
    # any animations. In either case, this method MUST NOT await.
    #
    # The default implementation behaves like
    # CardGameApi.broadcast_to_cards (resp.
    # CardGameApi.broadcast_to_cards_async) but will short-circuit
    # when it finds the first card that blocks the influence.
    # Additionally, the default implementation respects
    # CardMeta.HAS_SPECIAL_IMMUNITY.

    # Special immunity check
    if target_card.metadata.get(CardMeta.HAS_SPECIAL_IMMUNITY, false):
        if not CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently):
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
    #
    # This method MUST NOT await.
    return true


func do_passive_hero_check(_playing_field, _card, _hero_card) -> bool:
    # Called when a Hero card indicated by `hero_card` is about to
    # perform its effect. This method should return true (the default)
    # if the card is permitted to proceed as planned, and false if
    # this card is blocking the hero card. This method MAY NOT
    # `await`.
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
    # this card is blocking the hero card. This method MAY NOT
    # `await`. If this method returns false, the returning card will
    # be destroyed as a result of the active hero check. This method
    # SHALL NOT destroy the card itself.
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


func get_level_modifier(_playing_field, _this_card, _minion_card) -> int:
    # Called during the get_level calculation. This method should
    # return a numerical value by which to increase or decrease the
    # minion_card's Level, per this_card's effect. This method MUST
    # NOT await.
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


func is_nuclear() -> bool:
    # Returns true if this card has the word "Nuclear" in the name.
    # This method is currently unused, as it was only used for a
    # previous version of the Foreman's effect (Foreman used to be
    # restricted to "Nuclear" cards; now it applies to all timed
    # effect cards).
    #
    # This method MUST NOT await.
    return "Nuclear" in get_title()


func is_spiky_broadcasted(_playing_field, _this_card, _candidate_card) -> bool:
    # Broadcasted "Spiky" check for a Minion candidate card. See
    # MinionCardType.is_spiky for details.
    #
    # This method MUST NOT await.
    return false


func deepclone():
    # Card types are immutable, so cloning them simply returns the
    # original value. This method MUST NOT be overridden by any
    # subclasses, and is only provided for parity with the API of the
    # Card class.
    return self


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    # Given the current state of the game board, returns the score
    # assigned to this card. A positive score indicates that the AI
    # should play this card, with a higher score indicating a better
    # card to play in the current state of the game.
    #
    # A negative score does NOT necessarily mean that the AI will
    # refuse to play the card. For instance, if the AI's hand is full
    # of only negative score cards, it will likely choose to play at
    # least one in order to be able to draw again next turn.
    #
    # The default score of a card only takes into consideration its
    # cost. Minions will also take their default stats into
    # consideration (via an override on MinionCardType). Most cards
    # that have additional effects should override this method.
    #
    # This method MUST NOT await.
    return ai_get_score_base_calculation(playing_field, player, priorities)


func ai_get_score_base_calculation(playing_field, player: StringName, priorities) -> float:
    # The base function for ai_get_score. Subclasses can call this in
    # lieu of calling super(). Subclasses SHALL NOT override this
    # method.
    var score = - get_star_cost() * priorities.of(LookaheadPriorities.EVIL_POINT)
    for card in CardGameApi.get_cards_in_play(playing_field):
        score += card.card_type.ai_get_score_broadcasted(playing_field, card, player, priorities, self)
    for card_type in playing_field.get_hand(player).cards().card_array():
        score += card_type.ai_get_score_broadcasted_in_hand(playing_field, player, priorities, self)
    return score


func ai_get_score_broadcasted(_playing_field, _this_card, _player: StringName, _priorities, _target_card_type) -> float:
    # Broadcasted variant of ai_get_score. Called when this_card is in
    # the field and target_card_type is being considered for play from
    # the hand to the field.
    #
    # Note that this_card may or may not belong to the same owner as
    # the AI considering playing target_card_type.
    return 0.0


func ai_get_score_broadcasted_in_hand(_playing_field, _player: StringName, _priorities, _target_card_type) -> float:
    # Broadcasted variant of ai_get_score. Called when self is in the
    # player's hand and target_card_type is being considered for play
    # from the hand to the field.
    return 0.0


# Should return true if this card would MAKE the candidate card spiky
# if played right now. Default is constant false. See also
# MinionCardType.ai_will_be_spiky.
#
# This method MUST NOT await.
func ai_will_be_spiky_broadcasted(_playing_field, _this_card, _candidate_card_type, _candidate_owner):
    return false
