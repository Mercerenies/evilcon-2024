extends MinionCardType


func get_id() -> int:
    return 164


func get_title() -> String:
    return "Green Ranger"


func get_text() -> String:
    return "[font_size=12]Green Ranger is immune to enemy card effects. All [icon]NATURE[/icon] NATURE and [icon]BEE[/icon] BEE Minions you control are immune to enemy card effects.[/font_size]"


func get_picture_index() -> int:
    return 178


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NINJA]


func get_rarity() -> int:
    return Rarity.RARE


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        super.do_influence_check(playing_field, target_card, source_card, silently)
    )


func do_broadcasted_influence_check(playing_field, this_card, target_card, source_card, silently: bool) -> bool:
    if this_card.owner == target_card.owner and this_card.owner != source_card.owner:
        if target_card.has_archetype(playing_field, Archetype.BEE) or target_card.has_archetype(playing_field, Archetype.NATURE):
            if not silently:
                Stats.show_text(playing_field, target_card, PopupText.BLOCKED)
            return false
    return super.do_broadcasted_influence_check(playing_field, this_card, target_card, source_card, silently)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    # Immunity for self
    score += priorities.of(LookaheadPriorities.IMMUNITY)
    # Immunity for bees and nature minions
    var immune_minions = (
        Query.on(playing_field).minions(player)
        .count(Query.by_archetype([Archetype.BEE, Archetype.NATURE]))
    )
    score += priorities.of(LookaheadPriorities.IMMUNITY) * immune_minions
    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # All NATURE and BEE Minions are immune.
    if target_card_type is MinionCardType:
        var archetypes = target_card_type.get_base_archetypes()
        if Archetype.BEE in archetypes or Archetype.NATURE in archetypes:
            score += priorities.of(LookaheadPriorities.IMMUNITY)
    return score
