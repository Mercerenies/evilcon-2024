extends Node2D

const GreedyEnemyAI = preload("res://card_game/playing_field/enemy_ai/greedy_enemy_ai.tscn")


func _ready():
    $PlayingField.replace_enemy_ai(GreedyEnemyAI.instantiate())
    var bottom_deck = $PlayingField.get_deck(CardPlayer.BOTTOM)
    var top_deck = $PlayingField.get_deck(CardPlayer.TOP)
    bottom_deck.cards().replace_cards(_sample_deck())
    top_deck.cards().replace_cards(_sample_deck())
    bottom_deck.cards().shuffle()
    top_deck.cards().shuffle()

    $PlayingField.turn_number = 10  # Get extra EP :)
    $PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.WIMPY))
    $PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.METAL_CHICKEN))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.BABY_CLOWN), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.BABY_CLOWN), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNPAID_INTERN), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.DUCK), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.MILKMAN_MARAUDER), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE), CardPlayer.TOP))
    #$PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KIDNAPPING_THE_PRESIDENT), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE), CardPlayer.TOP))

    await CardGameTurnTransitions.begin_game($PlayingField)


func _sample_deck():
    return [
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FOREMAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CHRIS_COGSWORTH),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.NUCLEAR_FUSION_PLANT),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.NUCLEAR_POWER_PLANT),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.DESTRUCTION_TANK),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.INVASIVE_PARASITES),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.HIVEMIND),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ZOMBEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MUSHROOM_MAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORNY_ACORN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORNY_ACORN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.NINJA_MASK),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.METAL_CHICKEN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BOILING_POT_OF_WATER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.EXTENDED_WARRANTY),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CHICKEN),
    ]
