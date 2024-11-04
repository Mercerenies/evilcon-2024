extends MinionCardType

const WimpySmash = preload("res://card_game/playing_card/cards/wimpy_smash.gd")


func get_id() -> int:
    return 160


func get_title() -> String:
    return "Wimpy"


func get_text() -> String:
    return "[i]Some kid who always gets picked on in school. What can you expect from a poor kid whose mother named him \"Wimpy\"?[/i]"


func is_text_flavor() -> bool:
    return true


func get_picture_index() -> int:
    return 179


func get_star_cost() -> int:
    return 2


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN]


func get_rarity() -> int:
    return Rarity.COMMON


static func _wimpy_smash_star_cost() -> int:
    var wimpy_smash_temporary = WimpySmash.new()
    return wimpy_smash_temporary.get_star_cost()


func ai_get_score(playing_field, player: StringName, priorities) -> float:
    var score = super.ai_get_score(playing_field, player, priorities)
    var evil_points = playing_field.get_stats(player).evil_points

    # Count Wimpy Smashes in the hand that we can afford to play this
    # turn.
    var wimpy_smashes_in_hand = (
        Query.on(playing_field).hand(player).
        count(Query.by_id(PlayingCardCodex.ID.WIMPY_SMASH))
    )
    var playable_wimpy_smashes = mini(wimpy_smashes_in_hand, int(_wimpy_smash_star_cost() / evil_points))

    var level_increases_this_turn = 0
    if playable_wimpy_smashes > 0:
        # The first Wimpy Smash is worth 2. The rest are worth 4 each.
        level_increases_this_turn += 2 + 4 * (playable_wimpy_smashes - 1)

    score += level_increases_this_turn * get_base_morale() * priorities.of(LookaheadPriorities.FORT_DEFENSE)
    score -= playable_wimpy_smashes * _wimpy_smash_star_cost() * priorities.of(LookaheadPriorities.EVIL_POINT)
    return score
