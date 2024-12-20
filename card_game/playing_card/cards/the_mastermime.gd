extends MinionCardType


func get_id() -> int:
    return 115


func get_title() -> String:
    return "The Mastermime"


func get_text() -> String:
    return "All new Minions played by your opponent are now of type [icon]CLOWN[/icon] CLOWN."


func get_picture_index() -> int:
    return 109


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if this_card.owner == played_card.owner:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        Stats.show_text(playing_field, played_card, PopupText.CLOWNED)
        played_card.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # As of Nov 2, 2024, the average EP cost of a playing card is 3.2,
    # so assume that the opponent is playing 2 or 3 cards per turn.
    # Here, we assume the opponent is playing 2 Minion cards per turn.
    score += get_base_morale() * 2 * priorities.of(LookaheadPriorities.CLOWNING)
    return score
