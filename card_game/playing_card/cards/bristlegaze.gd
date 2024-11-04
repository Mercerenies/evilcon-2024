extends MinionCardType


func get_id() -> int:
    return 118


func get_title() -> String:
    return "Bristlegaze"


func get_text() -> String:
    return "Hero cards played by your opponent have no effect. Bristlegaze counts as a \"Spiky\" Minion."


func get_picture_index() -> int:
    return 54


func get_star_cost() -> int:
    return 7


func get_base_level() -> int:
    return 3


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func do_passive_hero_check(playing_field, card, hero_card) -> bool:
    if card.owner != hero_card.owner:
        return false
    return super.do_passive_hero_check(playing_field, card, hero_card)


func is_spiky(_playing_field, _this_card) -> bool:
    return true


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)

    # Bristlegaze is extra beneficial, as long as you don't control
    # another Bristlegaze or a Kidnapping the President.
    var passive_hostage_ids = [PlayingCardCodex.ID.KIDNAPPING_THE_PRESIDENT, PlayingCardCodex.ID.BRISTLEGAZE]
    if not Query.on(playing_field).effects(player).any(Query.by_id(passive_hostage_ids)):
        score += priorities.of(LookaheadPriorities.HOSTAGE)

    return score
