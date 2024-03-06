class_name Rarity
extends Node

const CardIcon = preload("res://card_game/playing_card/playing_card_display/card_icon/card_icon.gd")
const CardFrame = preload("res://card_game/playing_card/playing_card_display/card_frame/card_frame.gd")


const COMMON = 0
const UNCOMMON = 1
const RARE = 2
const ULTRA_RARE = 3


static func to_icon_index(rarity: int) -> int:
    match rarity:
        COMMON:
            return CardIcon.Frame.COMMON
        UNCOMMON:
            return CardIcon.Frame.UNCOMMON
        RARE:
            return CardIcon.Frame.RARE
        ULTRA_RARE:
            return CardIcon.Frame.ULTRA_RARE
        _:
            push_warning("No such rarity as %s" % rarity)
            return CardIcon.Frame.COMMON


static func to_frame_index(rarity: int) -> int:
    match rarity:
        COMMON:
            return CardFrame.Frame.COMMON
        UNCOMMON:
            return CardFrame.Frame.UNCOMMON
        RARE:
            return CardFrame.Frame.RARE
        ULTRA_RARE:
            return CardFrame.Frame.ULTRA_RARE
        _:
            push_warning("No such rarity as %s" % rarity)
            return CardFrame.Frame.COMMON
