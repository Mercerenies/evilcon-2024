extends MinionCardType


func get_id() -> int:
    return 128


func get_title() -> String:
    return "Barry"


func get_text() -> String:
    return "Each turn, during your End Phase, create a random Cost 2 [icon]ROBOT[/icon] ROBOT Minion."


func get_picture_index() -> int:
    return 48


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_end_phase(playing_field, card) -> void:
    if card.owner == playing_field.turn_player:
        await CardGameApi.highlight_card(playing_field, card)
        var chosen_card_id = playing_field.randomness.choose(PlayingCardLists.BARRYS_ROBOTS)
        var chosen_card_type = PlayingCardCodex.get_entity(chosen_card_id)
        await CardGameApi.create_card(playing_field, card.owner, chosen_card_type)
    await super.on_end_phase(playing_field, card)
