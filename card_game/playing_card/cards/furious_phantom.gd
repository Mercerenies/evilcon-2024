extends MinionCardType

const ZanyZombie = preload("res://card_game/playing_card/cards/zany_zombie.gd")

func get_id() -> int:
    return 48


func get_title() -> String:
    return "Furious Phantom"


func get_text() -> String:
    return "When Furious Phantom expires, play the top Zany Zombie from your discard pile."


func get_picture_index() -> int:
    return 57


func get_star_cost() -> int:
    return 3


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.UNDEAD]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_expire(playing_field, card) -> void:
    await super.on_expire(playing_field, card)
    var owner = card.owner
    var discard_pile = playing_field.get_discard_pile(owner)
    var zombie_index = discard_pile.cards().find_card_reversed_if(func (discarded_card):
        return discarded_card is ZanyZombie)
    if zombie_index != null:
        await CardGameApi.highlight_card(playing_field, card)
        var zombie_card_type = discard_pile.cards().peek_card(zombie_index)
        await CardGameApi.resurrect_card(playing_field, owner, zombie_card_type)
    else:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
            "offset": Stats.CARD_MULTI_UI_OFFSET,  # Don't overlap with the "-1 Morale" message.
        })
