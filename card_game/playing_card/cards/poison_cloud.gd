extends EffectCardType


func get_id() -> int:
    return 171


func get_title() -> String:
    return "Poison Cloud"


func get_text() -> String:
    return "[font_size=12] Minions played by your opponent are at -1 Level. During your Standby Phase, destroy this card if you have no [icon]NATURE[/icon] NATURE Minions.[/font_size]"


func is_ongoing() -> bool:
    return true


func get_star_cost() -> int:
    return 5


func get_picture_index() -> int:
    return 166


func get_rarity() -> int:
    return Rarity.RARE


func on_standby_phase(playing_field, this_card) -> void:
    if this_card.owner == playing_field.turn_player and not _has_any_nature_minions(playing_field, this_card.owner):
        await CardGameApi.highlight_card(playing_field, this_card)
        await CardGameApi.destroy_card(playing_field, this_card)


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if !(played_card.card_type is MinionCardType):
        return
    if this_card.owner == played_card.owner:
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        await Stats.add_level(playing_field, played_card, -1)


func _has_any_nature_minions(playing_field, owner) -> bool:
    var all_minions = playing_field.get_minion_strip(owner).cards().card_array()
    return all_minions.any(func(c): return c.has_archetype(playing_field, Archetype.NATURE))
