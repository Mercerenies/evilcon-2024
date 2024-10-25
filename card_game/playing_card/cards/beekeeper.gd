extends MinionCardType


func get_id() -> int:
    return 146


func get_title() -> String:
    return "Beekeeper"


func get_text() -> String:
    return "Instead of attacking, Beekeeper gives your most powerful [icon]BEE[/icon] BEE Minion +1 Morale."


func get_picture_index() -> int:
    return 143


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON


func on_attack_phase(playing_field, this_card) -> void:
    # Overrides and does NOT call super. Beekeeper does not perform a
    # regular attack, even if it has a nonzero Level.
    var owner = this_card.owner
    if playing_field.turn_player != owner:
        return
    await CardGameApi.highlight_card(playing_field, this_card)

    # Check if anything blocks the Attack Phase.
    var should_proceed = await CardEffects.do_attack_phase_check(playing_field, this_card)
    if not should_proceed:
        return

    var friendly_bees = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func (c): return c.has_archetype(playing_field, Archetype.BEE))
    )
    if len(friendly_bees) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
        return

    var most_powerful_bee = Util.max_by(friendly_bees, CardEffects.card_power_less_than(playing_field))
    var can_influence = await most_powerful_bee.card_type.do_influence_check(playing_field, most_powerful_bee, this_card, false)
    if not can_influence:
        return

    await Stats.add_morale(playing_field, most_powerful_bee, 1, {
        "offset": Stats.CARD_MULTI_UI_OFFSET,  # Just playing it safe with the -1 Morale message :)
    })

