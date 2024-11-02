extends TimedCardType


func get_id() -> int:
    return 176


func get_title() -> String:
    return "Defensive Formation"


func get_text() -> String:
    return "[font_size=12]Your [icon]TURTLE[/icon] TURTLE Minions do not attack. If you control any such Minions, then enemy Minions deal no damage to your base. Lasts 1 turn. Limit 1 per deck.[/font_size]"


func is_limited() -> bool:
    return true


func get_total_turn_count() -> int:
    return 1


func get_star_cost() -> int:
    return 6


func get_picture_index() -> int:
    return 173


func get_rarity() -> int:
    return Rarity.RARE


func do_attack_phase_check(playing_field, this_card, attacking_card) -> bool:
    if attacking_card.owner == this_card.owner and attacking_card.has_archetype(playing_field, Archetype.TURTLE):
        Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
            "offset": 1,
        })
        return false
    return super.do_attack_phase_check(playing_field, this_card, attacking_card)


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if not _owner_has_any_turtles(playing_field, this_card.owner):
        # Owner has no Turtles, so do nothing.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player as
        # the Defensive Formation
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    await CardGameApi.highlight_card(playing_field, this_card)

    var can_influence = attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
    if can_influence:  # TODO Consider if we can show this in the UI better, it's confusing right now
        Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
            "offset": 1,
        })
        return -99999

    return super.augment_attack_damage(playing_field, this_card, attacking_card)


func _owner_has_any_turtles(playing_field, owner) -> bool:
    var minions = playing_field.get_minion_strip(owner).cards().card_array()
    return minions.any(func(c): return c.has_archetype(playing_field, Archetype.TURTLE))
