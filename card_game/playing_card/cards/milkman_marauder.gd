extends MinionCardType


func get_id() -> int:
    return 126


func get_title() -> String:
    return "Milkman Marauder"


func get_text() -> String:
    return "When Milkman Marauder expires, all friendly Minions gain 1 Morale."


func get_picture_index() -> int:
    return 52


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var owner = this_card.owner

    await CardGameApi.highlight_card(playing_field, this_card)

    # Do not apply this effect to `self` (we don't want to resurrect `self`.
    var minion_strip = playing_field.get_minion_strip(owner)
    var minions = minion_strip.cards().card_array().filter(func(m): return m != this_card)

    if len(minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        for minion in minions:
            await Stats.add_morale(playing_field, minion, 1)
