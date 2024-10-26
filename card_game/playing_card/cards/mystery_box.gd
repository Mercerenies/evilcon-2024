extends EffectCardType


const PresentBoxAnimation = preload("res://card_game/playing_field/animation/present_box/present_box_animation.tscn")
const InputBlockAnimation = preload("res://card_game/playing_field/animation/input_block_animation.gd")


func get_id() -> int:
    return 130


func get_title() -> String:
    return "Mystery Box"


func get_text() -> String:
    return "Create and immediately play a random card."


func get_star_cost() -> int:
    return 1


func get_picture_index() -> int:
    return 135


func get_rarity() -> int:
    return Rarity.RARE


func on_play(playing_field, card) -> void:
    await super.on_play(playing_field, card)
    await _evaluate_effect(playing_field, card)
    await CardGameApi.destroy_card(playing_field, card)


func _evaluate_effect(playing_field, this_card) -> void:
    await CardGameApi.highlight_card(playing_field, this_card)

    var input_block = InputBlockAnimation.new()
    await playing_field.with_animation(func(animation_layer):
        animation_layer.add_child(input_block))

    var chosen_card_id = playing_field.randomness.choose(PlayingCardLists.MYSTERY_BOX_TARGETS)
    var chosen_card_type = PlayingCardCodex.get_entity(chosen_card_id)

    await playing_field.with_animation(func(animation_layer):
        await _play_present_box_animation(animation_layer, chosen_card_type))
    await CardGameApi.play_card_from_nowhere(playing_field, this_card.owner, chosen_card_type, _get_origin(playing_field))
    input_block.queue_free()


func _play_present_box_animation(animation_layer, chosen_card_type) -> void:
    var animation = PresentBoxAnimation.instantiate()
    animation.position = _get_origin(animation_layer)
    animation.set_card(chosen_card_type)
    animation_layer.add_child(animation)
    await animation.main_animation_completed


func _get_origin(any_node) -> Vector2:
    return any_node.get_viewport_rect().size / 2
