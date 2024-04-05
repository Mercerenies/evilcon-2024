extends MinionCardType

func get_id() -> int:
    return 76


func get_title() -> String:
    return "Disembodied Soul"


func get_text() -> String:
    return "Disembodied Soul has +1 Level for each [icon]UNDEAD[/icon] UNDEAD in your discard pile, up to a maximum of 5."


func get_picture_index() -> int:
    return 113


func get_star_cost() -> int:
    return 3


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.UNDEAD]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_level(playing_field, card) -> int:
    var own_discards = playing_field.get_discard_pile(card.owner).cards().card_array()
    var discarded_undeads = own_discards.filter(_is_undead_card_type)
    var starting_level = super.get_level(playing_field, card)
    return starting_level + mini(len(discarded_undeads), 5)


func _is_undead_card_type(card_type):
    if not (card_type is MinionCardType):
        return false
    # NOTE: get_base_archetypes since we're not in play and thus don't
    # have archetype modifiers.
    var archetypes = card_type.get_base_archetypes()
    return Archetype.UNDEAD in archetypes
