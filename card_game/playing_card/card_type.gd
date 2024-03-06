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


func get_icon_row() -> Array:
    if is_limited():
        return [CardIcon.Frame.LIMITED]
    else:
        return []


func get_star_cost() -> int:
    push_warning("Forgot to override get_star_cost!")
    return 0


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
