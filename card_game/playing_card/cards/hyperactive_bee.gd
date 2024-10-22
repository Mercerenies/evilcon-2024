extends MinionCardType


func get_id() -> int:
    return 163


func get_title() -> String:
    return "Hyperactive Bee"


func get_text() -> String:
    return "Hyperactive Bee attacks twice per turn."


func get_picture_index() -> int:
    return 176


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.BEE]


func get_rarity() -> int:
    return Rarity.RARE


func on_attack_phase(playing_field, this_card) -> void:
    # Hyperactive Bee performs its owner's Attack Phase twice.
    await super.on_attack_phase(playing_field, this_card)
    if playing_field.turn_player == this_card.owner:
        await super.on_attack_phase(playing_field, this_card)
