extends MinionCardType


func get_id() -> int:
    return 81


func get_title() -> String:
    return "Dr. Badguy Doomcake"


func get_text() -> String:
    return "When Dr. Badguy Doomcake expires, draw a random Hero card from your deck."


func get_picture_index() -> int:
    return 78


func get_star_cost() -> int:
    return 6


func get_base_level() -> int:
    return 2


func get_base_morale() -> int:
    return 3


func get_base_archetypes() -> Array:
    return [Archetype.HUMAN, Archetype.BOSS]


func get_rarity() -> int:
    return Rarity.ULTRA_RARE


func on_expire(playing_field, card) -> void:
    await super.on_expire(playing_field, card)
    var owner = card.owner

    await CardGameApi.highlight_card(playing_field, card)

    var deck = playing_field.get_deck(owner)
    var valid_targets = deck.cards().card_array().filter(func (deck_card):
        return deck_card is EffectCardType and deck_card.is_hero())
    if len(valid_targets) == 0:
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.NO_TARGET_TEXT,
            "custom_label_color": Stats.NO_TARGET_COLOR,
        })
    else:
        # Choose a target card and draw
        var target_card = playing_field.randomness.choose(valid_targets)
        await CardGameApi.draw_specific_card(playing_field, owner, target_card)
