extends MinionCardType


func get_id() -> int:
    return 82


func get_title() -> String:
    return "Farmer Blue"


func get_text() -> String:
    return "Instead of attacking, Farmer Blue summons the top [icon]FARM[/icon] FARM Minion from your deck to the field."


func get_picture_index() -> int:
    return 42


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_attack_phase(playing_field, card) -> void:
    # Overrides and does NOT call super. Farmer Blue does not
    # perform a regular attack, even if he has a nonzero Level.
    var owner = card.owner

    if playing_field.turn_player != owner:
        return

    await CardGameApi.highlight_card(playing_field, card)

    # Check if anything blocks the Attack Phase.
    var should_proceed = await CardEffects.do_attack_phase_check(playing_field, card)
    if not should_proceed:
        return

    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_farm_card_type)
    if len(valid_target_minions) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
            "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
        })
    else:
        # Choose a target minion and play
        var target_minion = valid_target_minions[-1]
        var new_card = await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)
        new_card.metadata[CardMeta.SKIP_MORALE] = true


func _is_farm_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes
