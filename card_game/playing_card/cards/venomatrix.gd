extends MinionCardType


func get_id() -> int:
    return 97


func get_title() -> String:
    return "Venomatrix"


func get_text() -> String:
    return "Venomatrix has +1 Level for each friendly [icon]BEE[/icon] BEE Minion in play (including Venomatrix)."


func get_level(playing_field, card) -> int:
    var friendly_minions = playing_field.get_minion_strip(card.owner).cards().card_array()
    var friendly_bees = friendly_minions.filter(func(minion):
        return minion.has_archetype(playing_field, Archetype.BEE))
    var starting_level = super.get_level(playing_field, card)
    return starting_level + len(friendly_bees)


func get_picture_index() -> int:
    return 55


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.BEE, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE
