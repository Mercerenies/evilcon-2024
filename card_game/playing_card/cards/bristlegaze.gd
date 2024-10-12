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
        var card_node = CardGameApi.find_card_node(playing_field, card)
        Stats.play_animation_for_stat_change(playing_field, card_node, 0, {
            "custom_label_text": Stats.BLOCKED_TEXT,
            "custom_label_color": Stats.BLOCKED_COLOR,
        })
        return false
    return await super.do_passive_hero_check(playing_field, card, hero_card)


func is_spiky(_playing_field, _this_card) -> bool:
    return true
