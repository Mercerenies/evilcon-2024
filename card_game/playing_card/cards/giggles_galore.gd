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
    var opposing_clowns = Query.on(playing_field).minions(opponent).count(Query.by_archetype(Archetype.CLOWN))
    var starting_level = super.get_level(playing_field, card)
    return starting_level + opposing_clowns


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var opponent = CardPlayer.other(player)
    var enemy_clown_count = Query.on(playing_field).minions(opponent).count(Query.by_archetype(Archetype.CLOWN))
    score += enemy_clown_count * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner == player or not (target_card_type is MinionCardType):
        return score
    if not (Archetype.CLOWN in target_card_type.get_base_archetypes()):
        return score
    # If the enemy controls Giggles Galore, then playing CLOWN Minions
    # powers up the enemy's card.
    var giggles_morale = this_card.card_type.get_morale(playing_field, this_card)
    score -= giggles_morale * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score
