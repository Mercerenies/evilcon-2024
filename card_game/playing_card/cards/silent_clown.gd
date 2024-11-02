extends MinionCardType


func get_id() -> int:
    return 143


func get_title() -> String:
    return "Silent Clown"


func get_text() -> String:
    return "[font_size=12]Silent Clown is immune to enemy card effects. When Silent Clown expires, a random enemy non-[icon]CLOWN[/icon] CLOWN Minion is now of type [icon]CLOWN[/icon] CLOWN.[/font_size]"


func get_picture_index() -> int:
    return 146


func get_star_cost() -> int:
    return 1


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.NINJA]


func get_rarity() -> int:
    return Rarity.COMMON


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        super.do_influence_check(playing_field, target_card, source_card, silently)
    )


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var opponent = CardPlayer.other(this_card.owner)
    await CardGameApi.highlight_card(playing_field, this_card)

    var enemy_targets = (
        playing_field.get_minion_strip(opponent).cards()
        .card_array()
        .filter(func (minion): return not minion.has_archetype(playing_field, Archetype.CLOWN))
    )

    if len(enemy_targets) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        var selected_target = playing_field.randomness.choose(enemy_targets)
        var can_influence = selected_target.card_type.do_influence_check(playing_field, selected_target, this_card, false)
        if can_influence:
            Stats.show_text(playing_field, selected_target, PopupText.CLOWNED)
            selected_target.metadata[CardMeta.ARCHETYPE_OVERRIDES] = [Archetype.CLOWN]
    playing_field.emit_cards_moved()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    score += priorities.of(LookaheadPriorities.IMMUNITY)
    # It is difficult to predict what Minions will be in play when
    # this card expires, so assume there will be at least one.
    score += priorities.of(LookaheadPriorities.CLOWNING)
    return score
