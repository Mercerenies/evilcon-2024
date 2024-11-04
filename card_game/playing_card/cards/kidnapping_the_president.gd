extends TimedCardType


func get_id() -> int:
    return 61


func get_title() -> String:
    return "Kidnapping the President"


func get_text() -> String:
    return "Hero cards played by your opponent have no effect. Lasts 2 turns."


func get_total_turn_count() -> int:
    return 2


func get_star_cost() -> int:
    return 2


func get_picture_index() -> int:
    return 98


func get_rarity() -> int:
    return Rarity.UNCOMMON


func do_passive_hero_check(playing_field, card, hero_card) -> bool:
    if card.owner != hero_card.owner:
        return false
    return super.do_passive_hero_check(playing_field, card, hero_card)


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Playing multiple Kidnapping the Presidents at the same time is
    # useless.
    if not Query.on(playing_field).effects(player).any(Query.by_id(get_id())):
        score += priorities.of(LookaheadPriorities.HOSTAGE)

    return score
