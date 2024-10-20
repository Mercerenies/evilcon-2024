extends EffectCardType

const BusyBee = preload("res://card_game/playing_card/cards/busy_bee.gd")
const WorkerBee = preload("res://card_game/playing_card/cards/worker_bee.gd")


func get_id() -> int:
    return 152


func get_title() -> String:
    return "Stinger Swarm"


func get_text() -> String:
    return "Summon all Busy Bee and Worker Bee Minions from your deck to the field immediately."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 161


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var cards_to_summon = (
        playing_field.get_deck(owner).cards().card_array()
        .filter(_is_valid_target_minion)
    )
    if len(cards_to_summon) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
            "offset": Stats.CARD_MULTI_UI_OFFSET,
        })
        return

    for target_card in cards_to_summon:
        await CardGameApi.play_card_from_deck(playing_field, owner, target_card)


func _is_valid_target_minion(card_type):
    if not (card_type is MinionCardType):
        return false
    return card_type.get_id() in [BusyBee.new().get_id(), WorkerBee.new().get_id()]
