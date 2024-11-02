extends TimedCardType


func get_id() -> int:
    return 168


func get_title() -> String:
    return "Shell Shield"


func get_text() -> String:
    return "If you control at least one [icon]TURTLE[/icon] TURTLE Minion, then enemy Level 1 Minions deal no damage. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 168


func get_rarity() -> int:
    return Rarity.COMMON


func augment_attack_damage(playing_field, this_card, attacking_card) -> int:
    if not _owner_has_any_turtles(playing_field, this_card.owner):
        # Owner has no Turtles, so do nothing.
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player as
        # the Shell Shield
        return super.augment_attack_damage(playing_field, this_card, attacking_card)
    if attacking_card.card_type.get_level(playing_field, attacking_card) > 1:
        # Level is too high, do not block.
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
