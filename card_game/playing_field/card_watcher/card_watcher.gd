extends RefCounted

# Node that keeps track of the cards it has seen and how many
# instances of each card it knows it has seen. Some of the more
# advanced AI engines use this to keep track of the opponent's deck
# (since the AI is assumed to know nothing about your deck when the
# game starts).


# Dictionary from integer card IDs to the count of the number of times
# we can be certain that it's in the deck. This dictionary will often
# undercount (if it hasn't seen a particular card) but will NEVER
# overcount.
var _known_cards := {}


# Observes all cards currently in play and visible in the discard pile
# for the given player.
func observe_field(playing_field, target_player: StringName) -> void:
    var visible_cards = get_all_visible_cards(playing_field, target_player)
    Util.merge_dicts_in_place(_known_cards, visible_cards, func(_key, a, b): return max(a, b))


static func get_all_visible_cards(playing_field, target_player: StringName) -> Dictionary:
    var result = {}
    for card in CardGameApi.get_cards_in_play(playing_field):
        if card.original_owner == target_player and not card.is_token():
            result[card.card_type.get_id()] = result.get(card.card_type.get_id(), 0) + 1
    for card_type in playing_field.get_discard_pile(target_player).cards().card_array():
        result[card_type.get_id()] = result.get(card_type.get_id(), 0) + 1
    return result


func _on_cards_moved(playing_field, target_player: StringName) -> void:
    observe_field(playing_field, target_player)
