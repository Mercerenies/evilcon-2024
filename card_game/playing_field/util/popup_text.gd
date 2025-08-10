class_name PopupText
extends Node

# Constants referencing common text that appears on top of cards as a
# result of effect evaluations.
const NO_TARGET = &"NO_TARGET"
const BLOCKED = &"BLOCKED"
const MISMATCH = &"MISMATCH"
const CLOWNED = &"CLOWNED"
const DEMONED = &"DEMONED"
const ROBOTED = &"ROBOTED"
const WILDED = &"WILDED"

class Text:
    var contents: String
    var color: Color

    func _init(contents: String, color: Color) -> void:
        self.contents = contents
        self.color = color


static func get_text(value: StringName):
    match value:
        &"NO_TARGET":
            return Text.new("No Target!", Color.BLACK)
        &"BLOCKED":
            return Text.new("Blocked!", Color.BLACK)
        &"MISMATCH":
            return Text.new("Mismatch!", Color.BLACK)
        &"CLOWNED":
            return Text.new("Clowned!", Color.WEB_PURPLE)
        &"DEMONED":
            return Text.new("Bedeviled!", Color.WEB_PURPLE)
        &"ROBOTED":
            return Text.new("Upgraded!", Color.WEB_PURPLE)
        &"WILDED":
            return Text.new("Wild!", Color.WEB_PURPLE)
        _:
            push_error("Invalid text value: %s" % value)
            return null
