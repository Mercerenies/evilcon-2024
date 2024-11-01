extends MinionCardType


func get_id() -> int:
    return 69


func get_title() -> String:
    return "Spiky Metal Turtle"


func get_text() -> String:
    return "Spiky Metal Turtle has +2 Level if you control any other [icon]TURTLE[/icon] TURTLE Minions."


func get_picture_index() -> int:
    return 100


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.ROBOT, Archetype.TURTLE]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func get_level(playing_field, card) -> int:
    var starting_level = super.get_level(playing_field, card)
    if Query.on(playing_field).minions(card.owner).filter([Query.by_archetype(Archetype.TURTLE), Query.not_equals(card)]).any():
        return starting_level + 2
    else:
        return starting_level


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    if Query.on(playing_field).minions(player).filter(Query.by_archetype(Archetype.TURTLE)).any():
        score += 2 * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
