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
    var friendly_minions = playing_field.get_minion_strip(card.owner).cards().card_array()
    var friendly_turtles = friendly_minions.filter(func(minion):
        return minion.has_archetype(playing_field, Archetype.TURTLE) and minion != card)
    var starting_level = super.get_level(playing_field, card)
    if len(friendly_turtles) > 0:
        return starting_level + 2
    else:
        return starting_level


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var friendly_minions = playing_field.get_minion_strip(player).cards().card_array()
    if friendly_minions.any(func(c): return c.has_archetype(playing_field, Archetype.TURTLE)):
        score += 2 * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
