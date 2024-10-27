extends TimedCardType


func get_id() -> int:
    return 180


func get_title() -> String:
    return "Alone in the Dark"


func get_text() -> String:
    return "If you control only one Minion, and that Minion is a [icon]DEMON[/icon] DEMON, it gets +2 Level. Lasts 3 turns."


func get_total_turn_count() -> int:
    return 3


func get_star_cost() -> int:
    return 3


func get_picture_index() -> int:
    return 186


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_level_modifier(playing_field, this_card, minion_card) -> int:
    var modifier = super.get_level_modifier(playing_field, this_card, minion_card)
    if this_card.owner != minion_card.owner:
        return modifier
    if not _owner_has_only_one_minion(playing_field, this_card.owner):
        return modifier
    if not minion_card.has_archetype(playing_field, Archetype.DEMON):
        return modifier
    return modifier + 2


func _owner_has_only_one_minion(playing_field, owner) -> bool:
    return playing_field.get_minion_strip(owner).cards().card_count() == 1
