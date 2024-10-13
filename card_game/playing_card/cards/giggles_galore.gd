extends MinionCardType


func get_id() -> int:
    return 125


func get_title() -> String:
    return "Giggles Galore"


func get_text() -> String:
    return "Giggles Galore has +1 Level for each [icon]CLOWN[/icon] CLOWN Minion controlled by your opponent."


func get_picture_index() -> int:
    return 50


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func get_level(playing_field, card) -> int:
    var opponent = CardPlayer.other(card.owner)
    var opposing_clowns = playing_field.get_minion_strip(opponent).cards().card_array().filter(func(minion):
        return minion.has_archetype(playing_field, Archetype.CLOWN))
    var starting_level = super.get_level(playing_field, card)
    return starting_level + len(opposing_clowns)
