class_name CardPlayer
extends Node

const BOTTOM := &"BOTTOM"
const TOP := &"TOP"


func other(card_player: StringName) -> StringName:
    if card_player == BOTTOM:
        return TOP
    else:
        return BOTTOM
