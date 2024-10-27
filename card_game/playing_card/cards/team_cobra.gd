extends EffectCardType

const HyperactiveBee = preload("res://card_game/playing_card/cards/hyperactive_bee.gd")
const GreenRanger = preload("res://card_game/playing_card/cards/green_ranger.gd")
const IceMoth = preload("res://card_game/playing_card/cards/ice_moth.gd")


func get_id() -> int:
    return 177


func get_title() -> String:
    return "Team Cobra!"


func get_text() -> String:
    return "If you control Hyperactive Bee, Green Ranger, and Ice Moth, then deal 15 damage to your opponent's fortress."


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 187


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await CardGameApi.highlight_card(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, card) -> void:
    var owner = card.owner
    var targets = _find_target_cards(playing_field, owner)
    if len(targets) < 3:
        Stats.show_text(playing_field, card, PopupText.NO_TARGET)
        return
    await _play_rotate_animation(playing_field, targets)

    await Stats.add_fort_defense(playing_field, CardPlayer.other(owner), -15)


func _play_animation_for_card(playing_field, tribute_card, promise) -> void:
    await CardGameApi.rotate_card(playing_field, tribute_card)
    promise.resolve()


func _play_rotate_animation(playing_field, target_cards: Array) -> void:
    var promises = target_cards.map(func (card):
        var promise = Promise.new()
        _play_animation_for_card(playing_field, card, promise)
        return promise)
    await Promise.async_all(promises)


func _find_target_cards(playing_field, owner):
    var matches = [
        _find_card_by_class(playing_field, owner, HyperactiveBee),
        _find_card_by_class(playing_field, owner, GreenRanger),
        _find_card_by_class(playing_field, owner, IceMoth),
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
