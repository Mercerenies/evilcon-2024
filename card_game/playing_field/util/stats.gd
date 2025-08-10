class_name Stats
extends Node

# Helpers for modifying stats, with accompanying animations. These
# functions can be awaited and will yield when the animation is
# completely played out, but it usually makes more sense to
# fire-and-forget them. All semantic changes to the game state are
# instantaneous, and only the animation is awaitable.

const NumberAnimation = preload("res://card_game/playing_field/animation/number/number_animation.tscn")
const GameStatsDict = preload("res://card_game/playing_field/game_stats_panel/game_stats_dict.gd")

# If you want to show two NumberAnimations on the same card at the
# same time, this is the standard offset to show the second one at.
# Pass this value as the { "offset": ... } keyword argument.
const CARD_MULTI_UI_OFFSET := Vector2(0, -32)

# TODO These constants are, I think, unused and superseded by those in
# PopupText. Consider removing.

const NO_TARGET_TEXT := "No Target!"
const NO_TARGET_COLOR := Color.BLACK

const BLOCKED_TEXT := "Blocked!"
const BLOCKED_COLOR := Color.BLACK

const CLOWNED_TEXT := "Clowned!"
const CLOWNED_COLOR := Color.WEB_PURPLE

const DEMONED_TEXT := "Bedeviled!"
const DEMONED_COLOR := Color.WEB_PURPLE

const ROBOTED_TEXT := "Upgraded!"
const ROBOTED_COLOR := Color.WEB_PURPLE

# No semantic change to stats, just the animation. This function can
# be called directly, but it usually makes more sense to call one of
# the other helpers, which also performs the semantic change.
#
# Accepted options:
#
# * custom_label_text (String) - Overrides the default label text on
#   the animation.
#
# * custom_label_color (Color) - Overrides the default label color on
#   the animation.
#
# * offset (Vector2) - Position offset from the target node. If
#   supplied as a scalar, it is multiplied by CARD_MULTI_UI_OFFSET.
static func play_animation_for_stat_change(playing_field, stat_node, delta: int, opts = {}) -> void:
    await playing_field.with_animation(func(animation_layer):
        var _stat_node = stat_node
        if _stat_node is Callable:
            _stat_node = _stat_node.call()
        var animation = NumberAnimation.instantiate()
        animation.position = animation_layer.to_local(_stat_node.global_position) + opts.get("offset", Vector2.ZERO)
        animation.amount = delta
        if opts.has("custom_label_text"):
            animation.custom_label_text = opts["custom_label_text"]
        if opts.has("custom_label_color"):
            animation.custom_label_color = opts["custom_label_color"]
        animation_layer.add_child(animation)
        await animation.animation_finished)


# Shows common card text. `text` should be a CardText.Text object or
# one of the StringName constants from PopupText.
#
# Accepted options:
#
# * offset (Vector2 or float) - Position offset from the target node. If
#   supplied as a scalar, it is multiplied by CARD_MULTI_UI_OFFSET.
static func show_text(playing_field, card, text, opts = {}) -> void:
    if text is StringName:
        text = PopupText.get_text(text)
    var offset = opts.get("offset", Vector2.ZERO)
    if offset is int or offset is float:
        offset = offset * CARD_MULTI_UI_OFFSET

    var card_node = CardGameApi.find_card_node(playing_field, card)
    await play_animation_for_stat_change(playing_field, card_node, 0, {
        "custom_label_text": text.contents,
        "custom_label_color": text.color,
        "offset": offset,
    })


static func set_evil_points(playing_field, player: StringName, new_value: int) -> void:
    var stats = playing_field.get_stats(player)
    var old_value = stats.evil_points
    stats.evil_points = new_value
    playing_field.emit_cards_moved()
    # Fire and forget
    play_animation_for_stat_change(playing_field, func(): return stats.get_evil_points_node(), new_value - old_value)


static func add_evil_points(playing_field, player: StringName, delta: int) -> void:
    var stats = playing_field.get_stats(player)
    await set_evil_points(playing_field, player, stats.evil_points + delta)


static func set_fort_defense(playing_field, player: StringName, new_value: int) -> void:
    var stats = playing_field.get_stats(player)
    var old_value = stats.fort_defense
    stats.fort_defense = new_value
    playing_field.emit_cards_moved()
    # Fire and forget
    play_animation_for_stat_change(playing_field, func(): return stats.get_fort_defense_node(), new_value - old_value)

    if stats.fort_defense <= 0:
        await playing_field.end_game(CardPlayer.other(player))


static func add_fort_defense(playing_field, player: StringName, delta: int) -> void:
    var stats = playing_field.get_stats(player)
    await set_fort_defense(playing_field, player, stats.fort_defense + delta)


static func set_destiny_song(playing_field, player: StringName, new_value: int) -> void:
    var stats = playing_field.get_stats(player)
    var old_value = stats.destiny_song
    stats.destiny_song = new_value
    playing_field.emit_cards_moved()
    # Fire and forget
    play_animation_for_stat_change(playing_field, func(): return stats.get_destiny_song_node(), new_value - old_value)

    if stats.destiny_song >= GameStatsDict.DESTINY_SONG_LIMIT:
        await playing_field.end_game(player)


static func add_destiny_song(playing_field, player: StringName, delta: int) -> void:
    var stats = playing_field.get_stats(player)
    await set_destiny_song(playing_field, player, stats.destiny_song + delta)


static func set_morale(playing_field, card, new_value: int, opts = {}) -> void:
    new_value = maxi(new_value, 0)
    var card_node = CardGameApi.find_card_node(playing_field, card)
    var old_value = card.metadata[CardMeta.MORALE]
    card.metadata[CardMeta.MORALE] = new_value
    playing_field.emit_cards_moved()
    # Fire and forget
    var animation_opts = {
        "custom_label_text": "%+d Morale" % (new_value - old_value),
    }
    animation_opts.merge(opts, true)
    play_animation_for_stat_change(playing_field, card_node, new_value - old_value, animation_opts)
    if new_value <= 0:
        await card.card_type.on_pre_expire(playing_field, card)
        if card.metadata[CardMeta.MORALE] <= 0:
            await card.card_type.on_expire(playing_field, card)
            await CardGameApi.destroy_card(playing_field, card)


static func add_morale(playing_field, card, delta: int, opts = {}) -> void:
    await set_morale(playing_field, card, card.metadata[CardMeta.MORALE] + delta, opts)


static func set_level(playing_field, card, new_value: int, opts = {}) -> void:
    new_value = maxi(new_value, 0)
    var card_node = CardGameApi.find_card_node(playing_field, card)
    var old_value = card.metadata[CardMeta.LEVEL]
    card.metadata[CardMeta.LEVEL] = new_value
    playing_field.emit_cards_moved()
    # Fire and forget
    var animation_opts = {
        "custom_label_text": "%+d Level" % (new_value - old_value),
    }
    animation_opts.merge(opts, true)
    play_animation_for_stat_change(playing_field, card_node, new_value - old_value, animation_opts)


static func add_level(playing_field, card, delta: int, opts = {}) -> void:
    await set_level(playing_field, card, card.metadata[CardMeta.LEVEL] + delta, opts)
