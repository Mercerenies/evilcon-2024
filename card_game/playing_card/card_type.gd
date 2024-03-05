class_name CardType
extends RefCounted

const EffectTextFont = preload("res://fonts/Raleway-Regular.ttf")
const FlavorTextFont = preload("res://fonts/Raleway-Italic.ttf")


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


func is_text_flavor() -> bool:
    return false


func get_text_font() -> Font:
    if is_text_flavor():
        return FlavorTextFont
    else:
        return EffectTextFont
