extends EffectCardType

const BusyBee = preload("res://card_game/playing_card/cards/busy_bee.gd")
const WorkerBee = preload("res://card_game/playing_card/cards/worker_bee.gd")


func get_id() -> int:
    return 153


func get_title() -> String:
    return "Hivemind"


func get_text() -> String:
    return "Destroy all friendly non-[icon]BEE[/icon] BEE Minions. Create an equal number of Busy Bee or Worker Bee Minions."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 162


func get_rarity() -> int:
    return Rarity.COMMON


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)
    var owner = this_card.owner
    var target_minions = (
        playing_field.get_minion_strip(owner).cards().card_array()
        .filter(func(c): return _is_valid_target_minion(playing_field, c))
    )

    if len(target_minions) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, this_card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
            "offset": Stats.CARD_MULTI_UI_OFFSET,
        })
        return

    var successful_destructions = 0
    for target_card in target_minions:
        var can_influence = await target_card.card_type.do_influence_check(playing_field, target_card, this_card, false)
        if can_influence:
            await CardGameApi.destroy_card(playing_field, target_card)
            successful_destructions += 1
    for _i in successful_destructions:
        var card_type_to_create = playing_field.randomness.choose([BusyBee, WorkerBee])
        await CardGameApi.create_card(playing_field, owner, card_type_to_create.new())


func _is_valid_target_minion(playing_field, card):
    if not (card.card_type is MinionCardType):
        return false
    return not card.has_archetype(playing_field, Archetype.BEE)
