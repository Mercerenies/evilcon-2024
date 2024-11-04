class_name CardEffects
extends Node

const CardMovingAnimation = preload("res://card_game/playing_field/animation/card_moving/card_moving_animation.tscn")

# Helpers for code that gets reused across several playing card
# effects.

# Powers up all Minions on the field which have at least one of the
# specified archetypes. The `archetypes` argument can either be a
# single Archetype constant or an array of them.
static func power_up_archetype(playing_field, source_card, archetypes) -> void:
    if archetypes is int:
        archetypes = [archetypes]
    var minions = CardGameApi.get_minions_in_play(playing_field)
    for minion in minions:
        if not _has_any_archetype(playing_field, minion, archetypes):
            continue
        var can_influence = minion.card_type.do_influence_check(playing_field, minion, source_card, false)
        if can_influence:
            await Stats.add_level(playing_field, minion, 1)


static func ai_score_for_powering_up_archetype(playing_field, source_card_type, player: StringName, archetypes, priorities) -> float:
    if archetypes is int:
        archetypes = [archetypes]
    var affected_total = (
        Query.on(playing_field).minions()
        .filter([Query.by_archetype(archetypes), Query.influenced_by(source_card_type, player)])
        .map_sum(func(playing_field, target_minion):
            var sign = 1 if target_minion.owner == player else -1
            return sign * target_minion.card_type.get_morale(playing_field, target_minion))
    )
    return affected_total * priorities.of(LookaheadPriorities.FORT_DEFENSE)


static func _has_any_archetype(playing_field, minion, archetypes: Array) -> bool:
    return archetypes.any(func (a): return minion.has_archetype(playing_field, a))


# Performs the ninja influence check for the specified card.
static func do_ninja_influence_check(playing_field, target_card, source_card, silently) -> bool:
    if target_card.owner != source_card.owner:
        if not silently:
            Stats.show_text(playing_field, target_card, PopupText.BLOCKED)
        return false
    return true


static func do_hero_check(playing_field, hero_card) -> bool:
    # Do the passive check first, then the active one. Short-circuit
    # if we find a match.
    var all_cards = CardGameApi.get_cards_in_play(playing_field)
    for card in all_cards:
        if not card.card_type.do_passive_hero_check(playing_field, card, hero_card):
            Stats.show_text(playing_field, card, PopupText.BLOCKED)
            return false
    for card in all_cards:
        if not card.card_type.do_active_hero_check(playing_field, card, hero_card):
            await CardGameApi.highlight_card(playing_field, card)
            Stats.show_text(playing_field, card, PopupText.BLOCKED)
            await CardGameApi.destroy_card(playing_field, card)
            return false
    return true


enum HeroCheckResult {
    PASS = 0,
    PASSIVE_FAIL = 1,
    ACTIVE_FAIL = 2,
}


static func do_hypothetical_hero_check(playing_field, hero_card_type, player: StringName) -> int:
    # Check to see if a Hero card would be blocked by a hostage
    # effect.
    #
    # NOTE CAREFULLY: Unlike the other "do_*_check" methods, this DOES
    # NOT return a Boolean. It returns a HeroCheckResult value,
    # indicating whether the Hero Check passes, or (if it fails), how
    # it fails, so that the AI engines that use this function can
    # prioritize getting rid of active hero checks if they so choose.
    var hypothetical_card = Card.new(hero_card_type, player)
    var all_cards = CardGameApi.get_cards_in_play(playing_field)
    for card in all_cards:
        if not card.card_type.do_passive_hero_check(playing_field, card, hypothetical_card):
            return HeroCheckResult.PASSIVE_FAIL
    for card in all_cards:
        if not card.card_type.do_active_hero_check(playing_field, card, hypothetical_card):
            return HeroCheckResult.ACTIVE_FAIL
    return HeroCheckResult.PASS


static func do_attack_phase_check(playing_field, attacking_card) -> bool:
    # Check if there's anything stopping this card from performing its
    # Attack Phase.
    var all_cards = CardGameApi.get_cards_in_play(playing_field)
    for card in all_cards:
        if not await card.card_type.do_attack_phase_check(playing_field, card, attacking_card):
            return false
    return true


static func do_morale_phase_check(playing_field, attacking_card) -> bool:
    # Check if there's anything stopping this card from performing its
    # Morale Phase.
    var all_cards = CardGameApi.get_cards_in_play(playing_field)
    for card in all_cards:
        if not await card.card_type.do_morale_phase_check(playing_field, card, attacking_card):
            return false
    return true


static func exile_top_of_deck(playing_field, player: StringName) -> void:
    var deck = playing_field.get_deck(player)
    if deck.cards().card_count() == 0:
        push_warning("Cannot exile top of empty deck")
        return
    var card = deck.cards().pop_card(-1)

    # Custom animation to show the card that's being exiled.
    await playing_field.with_animation(func(animation_layer):
        var animation = CardMovingAnimation.instantiate()
        var center_of_screen = playing_field.get_viewport().size / 2.0
        animation_layer.add_child(animation)
        animation.scale = Vector2(0.25, 0.25)
        animation.set_card(card)
        await animation.animate(deck.position, center_of_screen, {
            "start_angle": deck.global_rotation,
            "end_angle": 0.0,
        })

        await playing_field.get_tree().create_timer(0.50).timeout

        var displayed_card = animation.get_displayed_card()
        displayed_card.play_fade_out_animation()
        await CardGameApi.play_smoke_animation(playing_field, displayed_card)
        animation.queue_free())

    playing_field.emit_cards_moved()


# The "less than" comparison operator for Minion cards by their
# "power" level. This is the comparison used by all of the card
# effects that refer to the "most powerful" or "least powerful" Minion
# in play. This is a valid total ordering, and two cards are
# considered equivalent under this ordering if and only if they have
# the same stats and the same card type.
#
# Specifically, this function takes a playing_field and returns a
# binary comparison operator, since the calculation depends on the
# state of the playing field (as some cards will influence the level
# of other cards in play).
#
# The ordering used here is as follows:
#
# * Compare the Minions' Level.
#
# * In cases of equal Level, compare Morale.
#
# * If all stats are equal, compare card type ID (as an arbitrary but
#   consistent tiebreaker).
#
# * If that fails, consider the two cards equivalent.
#
# This comparison only makes sense for Minions and shall not be
# applied to Effect cards.
static func card_power_less_than(playing_field) -> Callable:
    return func less_than(a, b) -> bool:
        var level_a = a.card_type.get_level(playing_field, a)
        var level_b = b.card_type.get_level(playing_field, b)
        var morale_a = a.card_type.get_morale(playing_field, a)
        var morale_b = b.card_type.get_morale(playing_field, b)
        if level_a < level_b:
            return true
        elif level_a == level_b:
            if morale_a < morale_b:
                return true
            elif morale_a == morale_b:
                return (a.card_type.get_id() < b.card_type.get_id())
            else:
                return false
        else:
            return false


# Returns the most powerful Minion currently in play. If player is
# non-null, only Minions belonging to that player will be considered.
# Otherwise, all Minions in play are considered.
#
# Returns null if there are no minions in play satisfying the
# condition.
static func most_powerful_minion(playing_field, player):
    var all_minions = CardGameApi.get_minions_in_play(playing_field)
    if player != null:
        all_minions = all_minions.filter(func (minion): return minion.owner == player)
    return Util.max_by(all_minions, card_power_less_than(playing_field))


# Performs a hypothetical influence check for the given card type
# against a card already in play. Returns true if the prospective card
# could influence the target.
static func do_hypothetical_influence_check(playing_field, target_card: Card, activating_card_type, player: StringName) -> bool:
    var hypothetical_card = Card.new(activating_card_type, player)
    return target_card.card_type.do_influence_check(playing_field, target_card, hypothetical_card, true)
