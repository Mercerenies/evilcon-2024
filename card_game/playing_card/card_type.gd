class_name CardType
extends RefCounted

const EffectTextFont = preload("res://fonts/Raleway-Regular.ttf")
const FlavorTextFont = preload("res://fonts/Raleway-Italic.ttf")
const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")


func get_id() -> int:
    # Unique ID, must be unique among CardType subclasses.
    push_warning("Forgot to override get_id!")
    return -1


func get_title() -> String:
    push_warning("Forgot to override get_title!")
    return ""


func get_text() -> String:
    push_warning("Forgot to override get_text!")
    return ""


func get_picture_index() -> int:
    push_warning("Forgot to override get_picture_index!")
    return 0


func get_rarity() -> int:
    push_warning("Forgot to override get_rarity!")
    return 0


func get_destination_strip(_playing_field, _owner: StringName):
    push_warning("Forgot to override get_destination_strip!")
    return null


func get_icon_row() -> Array:
    if is_limited():
        return [CardIcon.Frame.LIMITED]
    else:
        return []


func get_star_cost() -> int:
    push_warning("Forgot to override get_star_cost!")
    return 0


func get_stats_text() -> String:
    push_warning("Forgot to override get_stats_text!")
    return ""


func is_text_flavor() -> bool:
    return false


func is_limited() -> bool:
    return false


func get_text_font() -> Font:
    if is_text_flavor():
        return FlavorTextFont
    else:
        return EffectTextFont


func get_archetypes_row_text() -> String:
    return ""


func can_play(playing_field, owner: StringName) -> bool:
    # Default implementation simply checks EP, which should be
    # sufficient in most, if not all, cases.
    var card_cost = get_star_cost()
    var user_evil_points = playing_field.get_stats(owner).evil_points
    return user_evil_points >= card_cost
