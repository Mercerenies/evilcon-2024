extends MinionCardType


func get_id() -> int:
    return 40


func get_title() -> String:
    return "Queen Bee"


func get_text() -> String:
    return "Queen Bee has +1 Level for each friendly [icon]BEE[/icon] BEE Minion in play (including Queen Bee)."


func get_level(playing_field, card) -> int:
    var starting_level = super.get_level(playing_field, card)
    var friendly_bee_count = Query.on(playing_field).minions(card.owner).count(Query.by_archetype(Archetype.BEE))
    return starting_level + friendly_bee_count


func get_picture_index() -> int:
    return 62


func get_star_cost() -> int:
    return 3


func get_base_level() -> int:
    return 0


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.BEE]


func get_rarity() -> int:
    return Rarity.RARE


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var base_score = super.ai_get_score(playing_field, player, priorities)
    # Note: +1 because Queen Bee counts herself when in play.
    var friendly_bee_count = Query.on(playing_field).minions(player).count(Query.by_archetype(Archetype.BEE)) + 1
    return base_score + friendly_bee_count * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
