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

    await CardGameApi.highlight_card(playing_field, card)

    # Check if anything blocks the Attack Phase.
    var should_proceed = await CardEffects.do_attack_phase_check(playing_field, card)
    if not should_proceed:
        return

    var enemy_target = (
        Query.on(playing_field).minions(CardPlayer.other(owner))
        .filter(Query.not_(Query.by_archetype(Archetype.CLOWN)))
        .random()
    )
    if enemy_target == null:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET, {
            "offset": 1,
        })
    else:
        var can_influence = enemy_target.card_type.do_influence_check(playing_field, enemy_target, card, false)
        if can_influence:
            Stats.show_text(playing_field, enemy_target, PopupText.CLOWNED)
            enemy_target.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # Assume that there will be targets, i.e. that this Minion will
    # successfully convert three enemies.
    score += get_base_morale() * priorities.of(LookaheadPriorities.CLOWNING)
    return score
