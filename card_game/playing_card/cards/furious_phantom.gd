extends MinionCardType

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
    var zombie = Query.on(playing_field).discard_pile(owner).find(Query.by_id(PlayingCardCodex.ID.ZANY_ZOMBIE))
    await CardGameApi.highlight_card(playing_field, this_card)
    if zombie != null:
        await CardGameApi.resurrect_card(playing_field, owner, zombie)
    else:
        Stats.show_text(playing_field, this_card, PopupText.NO_TARGET, {
            "offset": 1,
        })
