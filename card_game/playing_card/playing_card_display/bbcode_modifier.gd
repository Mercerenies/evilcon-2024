extends Node

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")

const ICON_IMAGE_PATH = "res://card_game/playing_card/playing_card_display/card_icon/card_icon.png"

var card_icon_bbcode_regex = null


func _ready() -> void:
    card_icon_bbcode_regex = RegEx.new()
    card_icon_bbcode_regex.compile(
        "\\[icon\\]([\\w\\d_]+)\\[/icon\\]",
    )


# Helper for processing the BBCode text on card descriptions.
func process_bbcode(bbcode: String) -> String:
    return Util.replace_all_by_function(bbcode, card_icon_bbcode_regex, _replace_with_image_tag)


func _replace_with_image_tag(regex_match: RegExMatch) -> String:
    var icon_name = regex_match.get_string(1)
    var icon_index = CardIcon.Frame[icon_name.to_upper()]
    if icon_index == null:
        push_error("Icon name %s is not valid." % icon_name)
        icon_index = CardIcon.Frame.EVIL_STAR

    # Get the coordinates of the icon in the image.
    var dims = Vector2i(CardIcon.ICON_WIDTH, CardIcon.ICON_HEIGHT)
    var pos = Vector2i(icon_index % CardIcon.ICONS_PER_ROW, int(icon_index / CardIcon.ICONS_PER_ROW)) * dims

    return "[img region=%d,%d,%d,%d]%s[/img]" % [pos.x, pos.y, dims.x, dims.y, ICON_IMAGE_PATH]
