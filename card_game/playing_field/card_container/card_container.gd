extends Node

# Container of zero or more cards or card types. The last card in the
# contained array is the "top" card, for the purposes of functions
# that treat this container like a stack (push, pop, etc)

signal cards_modified

@export_enum("Card", "CardType") var contained_type = "CardType"

var _array: Array = []


func _validate_type(card) -> bool:
    match contained_type:
        "Card":
            if not (card is Card):
                push_error("Expected a Card, got %s" % card)
                return false
        "CardType":
            if not (card is CardType):
                push_error("Expected a CardType, got %s" % card)
                return false
        _:
            push_warning("Invalid contained_type %s" % contained_type)
    return true


func replace_cards(cards: Array) -> void:
    _array = []
    # Validate each card before inserting
    for card in cards:
        if _validate_type(card):
            _array.append(card)
    cards_modified.emit()


func card_array() -> Array:
    return _array.duplicate()


func clear_cards() -> void:
    _array.clear()
    cards_modified.emit()


func card_count() -> int:
    return len(_array)


func peek_card(index: int = -1):
    return _array[index]


func pop_card(index: int = -1):
    if index < 0:
        index += len(_array)
    var card = _array[index]
    _array.remove_at(index)
    cards_modified.emit()
    return card


func push_card(card):
    if _validate_type(card):
        _array.push_back(card)
    cards_modified.emit()


func is_empty() -> bool:
    return _array.is_empty()


func shuffle() -> void:
    _array.shuffle()
    cards_modified.emit()


func find_card(card):
    # Godot's find() method returns index -1 for "not found", which
    # can be easily mistaken for "last element of the list", since
    # many of our indexing functions accept that convention. So return
    # null for "not found".
    return find_card_if(func (x): return card == x)


func find_card_if(callable: Callable):
    for i in range(len(_array)):
        if callable.call(_array[i]):
            return i
    return null
