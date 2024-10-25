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


func on_expire(playing_field, this_card) -> void:
    await super.on_expire(playing_field, this_card)
    var owner = this_card.owner
    var discard_pile = playing_field.get_discard_pile(owner)
    var zombie_index = discard_pile.cards().find_card_reversed_if(func (discarded_card):
        return discarded_card is ZanyZombie)
    await CardGameApi.highlight_card(playing_field, this_card)
    if zombie_index != null:
        var zombie_card_type = discard_pile.cards().peek_card(zombie_index)
        await CardGameApi.resurrect_card(playing_field, owner, zombie_card_type)
    else:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET, {
            "offset": 1,
        })
