extends TimedCardType


func get_id() -> int:
    return 84


func get_title() -> String:
    return "Hypercube Prison"


func get_text() -> String:
    return "Your opponent's most powerful Minion skips its Attack Phase. Lasts 1 turns."


func get_total_turn_count() -> int:
    return 1


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 85


func get_rarity() -> int:
    return Rarity.COMMON


func do_attack_phase_check(playing_field, this_card, attacking_card) -> bool:
    if attacking_card.owner == this_card.owner:
        # Do not block attacks originating from the same player as
        # Hypercube Prison.
        return super.do_attack_phase_check(playing_field, this_card, attacking_card)
    var most_powerful_minion = CardEffects.most_powerful_minion(playing_field, attacking_card.owner)
    if most_powerful_minion == attacking_card:
        await CardGameApi.highlight_card(playing_field, this_card)
        var can_influence = attacking_card.card_type.do_influence_check(playing_field, attacking_card, this_card, false)
        if can_influence:  # TODO Consider if we can show this in the UI better, it's confusing right now
            Stats.show_text(playing_field, attacking_card, PopupText.BLOCKED, {
                "offset": 1,
            })
            return false
    return super.do_attack_phase_check(playing_field, this_card, attacking_card)
