extends MinionCardType


func get_id() -> int:
    return 127


func get_title() -> String:
    return "Maxwell Sterling"


func get_text() -> String:
    return "[font_size=12]Maxwell Sterling does not attack or decrease Morale. When another [icon]HUMAN[/icon] HUMAN Minion you control would expire, Maxwell donates 1 Morale to that Minion.[/font_size]"


func get_picture_index() -> int:
    return 51


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 4


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_attack_phase(_playing_field, _card) -> void:
    # Overrides and does NOT call super. Maxwell Sterling does nothing
    # during the Attack Phase.
    pass


func on_morale_phase(_playing_field, _card) -> void:
    # Overrides and does NOT call super. Maxwell Sterling does nothing
    # during the Morale Phase.
    pass


func on_pre_expire_broadcasted(playing_field, this_card, expiring_card) -> void:
    if expiring_card.owner != this_card.owner or expiring_card.card_type.get_id() == this_card.card_type.get_id():
        # Do not apply to enemy Minions, or to other instances of
        # Maxwell Sterling. The latter is just to prevent infinite
        # loops, even though it should be impossible for there to be
        # two Maxwell Sterlings in the same deck.
        return
    if expiring_card.has_archetype(playing_field, Archetype.HUMAN):
        await CardGameApi.highlight_card(playing_field, this_card)
        await Stats.add_morale(playing_field, expiring_card, 1)
        await Stats.add_morale(playing_field, this_card, -1)
