extends MinionCardType


func get_id() -> int:
    return 145


func get_title() -> String:
    return "Cultist"


func get_text() -> String:
    return "Instead of attacking, Cultist gains 1 Level."


func get_picture_index() -> int:
    return 142


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON


func on_attack_phase(playing_field, this_card) -> void:
    # Overrides and does NOT call super. Farmer Cultist does not
    # perform a regular attack, even if he has a nonzero Level.
    var owner = this_card.owner
    if playing_field.turn_player != owner:
        return
    await CardGameApi.highlight_card(playing_field, this_card)

    # Check if anything blocks the Attack Phase.
    var should_proceed = await CardEffects.do_attack_phase_check(playing_field, this_card)
    if not should_proceed:
        return

    await Stats.add_level(playing_field, this_card, 1, {
        "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
    })
