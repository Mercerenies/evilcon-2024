extends MinionCardType


const BusyBee = preload("res://card_game/playing_card/cards/busy_bee.gd")
const WorkerBee = preload("res://card_game/playing_card/cards/worker_bee.gd")


func get_id() -> int:
    return 47


func get_title() -> String:
    return "Beehive"


func get_text() -> String:
    return "Each turn, during your End Phase, create a Busy Bee or a Worker Bee."


func get_picture_index() -> int:
    return 43


func get_star_cost() -> int:
    return 4


func get_base_level() -> int:
    return 1


func get_base_morale() -> int:
    return 2


func get_base_archetypes() -> Array:
    return [Archetype.BEE]


func get_rarity() -> int:
    return Rarity.UNCOMMON


func on_end_phase(playing_field, card) -> void:
    if card.owner != playing_field.turn_player:
        return

    var minion_strip = playing_field.get_minion_strip(card.owner)

    await CardGameApi.highlight_card(playing_field, card)

    var chosen_card_type = playing_field.randomness.choose([BusyBee, WorkerBee]).new()
    # TODO Animate
    var new_card = Card.new(chosen_card_type, card.owner, { "is_token": true })
    minion_strip.cards().push_card(new_card)
