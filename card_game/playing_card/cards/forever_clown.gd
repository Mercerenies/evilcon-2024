extends MinionCardType


func get_id() -> int:
    return 78


func get_title() -> String:
    return "Forever Clown"


func get_text() -> String:
    return "[font_size=12]Instead of attacking, Forever Clown chooses a random enemy non-[icon]CLOWN[/icon] CLOWN Minion each turn; that Minion is now of type [icon]CLOWN[/icon] CLOWN.[/font_size]"


func get_picture_index() -> int:
    return 46


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_attack_phase(playing_field, card) -> void:
    # Overrides and does NOT call super. Forever Clown does not
    # perform a regular attack, even if he has a nonzero Level.
    var owner = card.owner

    if playing_field.turn_player != owner:
        return

    var enemy_targets = (
        playing_field.get_minion_strip(CardPlayer.other(owner)).cards()
        .card_array()
        .filter(func (minion): return not minion.has_archetype(playing_field, Archetype.CLOWN))
    )
    await CardGameApi.highlight_card(playing_field, card)


    # Check if anything blocks the Attack Phase.
    var should_proceed = await CardEffects.do_attack_phase_check(playing_field, card)
    if not should_proceed:
        return

    if len(enemy_targets) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        var selected_target = playing_field.randomness.choose(enemy_targets)
        var can_influence = await selected_target.card_type.do_influence_check(playing_field, selected_target, card, false)
        if can_influence:
            Stats.show_text(playing_field, selected_target, PopupText.CLOWNED)
            selected_target.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()
