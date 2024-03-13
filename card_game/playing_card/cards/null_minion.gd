extends MinionCardType

# This minion card should never appear in the game proper. It's used
# as the front face for cards whose back is showing (e.g., this is the
# front face of cards in the enemy's hand that you should not be able
# to see)

func get_id() -> int:
    return 0  # Note: ID 0 does not show up in the shop, codex, or any player-facing environment


func get_title() -> String:
    return "Null Minion"


func get_text() -> String:
    return "Null Card"


func get_star_cost() -> int:
    return 8


func get_picture_index() -> int:
    return 0


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 1


func get_archetypes() -> Array:
    return []


func get_rarity() -> int:
    return Rarity.COMMON
