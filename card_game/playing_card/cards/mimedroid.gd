extends MinionCardType


func get_id() -> int:
    return 63


func get_title() -> String:
    return "Mimedroid"


func get_text() -> String:
    return "When a friendly [icon]CLOWN[/icon] CLOWN Minion expires, Mimedroid gets +1 Level."


func get_picture_index() -> int:
    return 106


func get_star_cost() -> int:
    return 5


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.CLOWN, Archetype.ROBOT]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_expire_broadcasted(playing_field, card, expiring_card) -> void:
    await super.on_expire_broadcasted(playing_field, card, expiring_card)
    if expiring_card.has_archetype(playing_field, Archetype.CLOWN) and expiring_card.owner == card.owner and expiring_card != card:
        await Stats.add_level(playing_field, card, 1)


@warning_ignore("CONFUSABLE_LOCAL_DECLARATION")
func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var clown_expires = (
        Query.on(playing_field).minions(player)
        .filter(Query.by_archetype(Archetype.CLOWN))
        .map(_ai_turns_after_expiry)
        .reduce(Operator.plus, 0)
    )
    score += clown_expires * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    return score


func _ai_turns_after_expiry(playing_field, card) -> int:
    # Returns the number of turns that Mimedroid will be on the field
    # after the given Minion expires. Returns 0 if the Minion will
    # expire after Mimedroid.
    return maxi(0, get_base_morale() - card.card_type.get_morale(playing_field, card))


func ai_get_score_broadcasted(playing_field, this_card, player: StringName, priorities, target_card_type) -> float:
    var score = super.ai_get_score_broadcasted(playing_field, this_card, player, priorities, target_card_type)
    if this_card.owner != player:
        return score

    # If the target is a ClOWN Minion who will live a shorter life
    # than Mimedroid, we should play it.
    if target_card_type is MinionCardType and Archetype.CLOWN in target_card_type.get_base_archetypes():
        var extra_turns = maxi(0, this_card.card_type.get_morale(playing_field, this_card) - target_card_type.get_base_morale())
        score += extra_turns * priorities.of(LookaheadPriorities.FORT_DEFENSE)

    return score
