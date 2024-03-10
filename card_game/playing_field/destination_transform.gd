class_name DestinationTransform
extends Node

# Static class containing methods frequently passed as the
# destination_transform optional argument to PlayingField.move_card.

static func instantiate_card_with_owner(card_type: CardType, owner_name: StringName) -> Card:
    return Card.new(card_type, owner_name)


# Instantiates a card type as a card with the given owner. This
# transform should be used when a card is being brought into the field
# from somewhere out of play.
static func instantiate_card(owner_name: StringName):
    return DestinationTransform.instantiate_card_with_owner.bind(owner_name)


# Strips a card back down to its card type. This transform should be
# used when a card is being taken out of play to be put into a hand,
# deck, or discard pile, or is being exiled completely.
static func strip_to_card_type(card: Card) -> CardType:
    return card.card_type
