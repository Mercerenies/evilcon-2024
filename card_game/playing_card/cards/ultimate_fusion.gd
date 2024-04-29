extends EffectCardType

const Chicken = preload("res://card_game/playing_card/cards/chicken.gd")
const Turkey = preload("res://card_game/playing_card/cards/turkey.gd")
const Duck = preload("res://card_game/playing_card/cards/duck.gd")
const Turducken = preload("res://card_game/playing_card/cards/turducken.gd")


func get_id() -> int:
    return 104


func get_title() -> String:
    return "Ultimate Fusion"


func get_text() -> String:
    return "Destroy a Chicken, Turkey, and Duck on your side of the field; if you do so, create a Turducken with +3 Level and immunity to enemy card effects."


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 120


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    var tributes = _find_tribute_cards(playing_field, owner)
    if len(tributes) < 3:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
        return
    await _play_rotate_animation(playing_field, tributes)
    for tribute_card in tributes:
        # TODO Do we need to do influence checks here? If one of the
        # influence checks fails, I guess the whole fusion fails.
        await CardGameApi.destroy_card(playing_field, tribute_card)
    var turducken_card = await CardGameApi.create_card(playing_field, owner, Turducken.new())
    turducken_card.metadata[CardMeta.HAS_SPECIAL_IMMUNITY] = true
    playing_field.emit_cards_moved()
    await Stats.add_level(playing_field, turducken_card, 3)

func _play_animation_for_card(playing_field, tribute_card, promise) -> void:
    await CardGameApi.rotate_card(playing_field, tribute_card)
    promise.resolve()


func _play_rotate_animation(playing_field, tribute_cards: Array) -> void:
    var promises = tribute_cards.map(func (card):
        var promise = Promise.new()
        _play_animation_for_card(playing_field, card, promise)
        return promise)
    await Promise.async_all(promises)


func _find_tribute_cards(playing_field, owner):
    var matches = [
        _find_card_by_class(playing_field, owner, Chicken),
        _find_card_by_class(playing_field, owner, Duck),
        _find_card_by_class(playing_field, owner, Turkey),
    ]
    return matches.filter(func (c): return c != null)


func _find_card_by_class(playing_field, owner, card_class):
    # On the offchance we find multiple matches (e.g. you have
    # multiple Turkeys in play), we take the weakest one for tribute.
    var target_id = card_class.new().get_id()
    var minions_in_play = playing_field.get_minion_strip(owner).cards().card_array()
    var matching_minions = minions_in_play.filter(func (c): return c.card_type.get_id() == target_id)
    if len(matching_minions) == 0:
        return null
    else:
        return Util.min_by(matching_minions, CardEffects.card_power_less_than(playing_field))
