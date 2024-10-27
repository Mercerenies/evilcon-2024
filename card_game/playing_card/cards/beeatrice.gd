extends MinionCardType


func get_id() -> int:
    return 187


func get_title() -> String:
    return "Beeatrice"


func get_text() -> String:
    return "When Beeatrice expires, all friendly [icon]BEE[/icon] BEE Minions gain 1 Morale."


func get_picture_index() -> int:
    return 198


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, card) -> void:
    await super.on_expire(playing_field, card)
    var owner = card.owner

    await CardGameApi.highlight_card(playing_field, card)

    var friendly_bees = (
        playing_field.get_minion_strip(owner)
        .cards().card_array()
        .filter(func (m): return m.has_archetype(playing_field, Archetype.BEE))
    )

    if len(friendly_bees) == 0:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
    else:
        for minion in friendly_bees:
            await Stats.add_morale(playing_field, minion, 1)
