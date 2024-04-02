extends MinionCardType


func get_id() -> int:
    return 63


func get_title() -> String:
    return "Mimedroid"


func get_text() -> String:
    return "When a friendly [icon]CLOWN[/icon] CLOWN Minion expires, Mimedroid gets +1 Level."


func get_picture_index() -> int:
    return 106


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_expire_broadcasted(playing_field, card, expiring_card) -> void:
    await super.on_expire_broadcasted(playing_field, card, expiring_card)
    if expiring_card.has_archetype(playing_field, Archetype.CLOWN) and expiring_card.owner == card.owner and expiring_card != card:
        await Stats.add_level(playing_field, card, 1)
