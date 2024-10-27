extends EffectCardType


func get_id() -> int:
    return 183


func get_title() -> String:
    return "Livestock Delivery"


func get_text() -> String:
    return "Summon the top [icon]FARM[/icon] FARM Minion from your deck to the field."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 185


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var deck = playing_field.get_deck(owner)
    var valid_target_minions = deck.cards().card_array().filter(_is_farm_card_type)
    if len(valid_target_minions) == 0:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET)
    else:
        # Choose a target minion and play
        var target_minion = valid_target_minions[-1]
        var new_card = await CardGameApi.play_card_from_deck(playing_field, owner, target_minion)
        new_card.metadata[CardMeta.SKIP_MORALE] = true


func _is_farm_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.FARM in archetypes
