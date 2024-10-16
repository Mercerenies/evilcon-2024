extends MinionCardType


func get_id() -> int:
    return 144


func get_title() -> String:
    return "Foreman"


func get_text() -> String:
    return "Cards you play with \"Nuclear\" in the name last 1 extra turn."


func get_picture_index() -> int:
    return 144


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON


func on_play_broadcasted(playing_field, this_card, played_card) -> void:
    super.on_play_broadcasted(playing_field, this_card, played_card)
    if this_card.owner != played_card.owner:
        return
    if not played_card.card_type.is_nuclear():
        return
    if not (CardMeta.TURN_COUNTER in played_card.metadata):
        return

    await CardGameApi.highlight_card(playing_field, this_card)
    var can_influence = await played_card.card_type.do_influence_check(playing_field, played_card, this_card, false)
    if can_influence:
        played_card.metadata[CardMeta.TURN_COUNTER] -= 1
    playing_field.emit_cards_moved()
