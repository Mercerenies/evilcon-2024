extends MinionCardType

func get_id() -> int:
    return 76


func get_title() -> String:
    return "Disembodied Soul"


func get_text() -> String:
    return "Disembodied Soul has +1 Level for each [icon]UNDEAD[/icon] UNDEAD Minion in your discard pile, up to a maximum of 5."


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
    var starting_level = super.get_level(playing_field, card)
    var undeads_count = Query.on(playing_field).discard_pile(card.owner).count(Query.by_archetype(Archetype.UNDEAD))
    return starting_level + mini(undeads_count, 5)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var undeads_count = Query.on(playing_field).discard_pile(player).count(Query.by_archetype(Archetype.UNDEAD))
    score += mini(undeads_count, 5) * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
