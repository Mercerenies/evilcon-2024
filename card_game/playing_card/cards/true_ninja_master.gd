extends MinionCardType


func get_id() -> int:
    return 114


func get_title() -> String:
    return "True Ninja Master"


func get_text() -> String:
    return "True Ninja Master is immune to enemy card effects. All [icon]HUMAN[/icon] HUMAN Minions you control are immune to enemy card effects."


func get_picture_index() -> int:
    return 137


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.NINJA, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func do_influence_check(playing_field, target_card, source_card, silently: bool) -> bool:
    return (
        await CardEffects.do_ninja_influence_check(playing_field, target_card, source_card, silently) and
        await super.do_influence_check(playing_field, target_card, source_card, silently)
    )


func do_broadcasted_influence_check(playing_field, this_card, target_card, source_card, silently: bool) -> bool:
    if this_card.owner == target_card.owner and this_card.owner != source_card.owner:
        if target_card.has_archetype(playing_field, Archetype.HUMAN):
            if not silently:
                var card_node = CardGameApi.find_card_node(playing_field, target_card)
                Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
                    "custom_label_text": Stats.BLOCKED_TEXT,
                    "custom_label_color": Stats.BLOCKED_COLOR,
                    "offset": Stats.CARD_MULTI_UI_OFFSET,  # Just in case, since this can overlap "-1 Morale"
                })
            return false
    return await super.do_broadcasted_influence_check(playing_field, this_card, target_card, source_card, silently)