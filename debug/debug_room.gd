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
    $PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.SQUAREDUDE))
    $PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.CIRCLEGIRL))
    $PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE), CardPlayer.BOTTOM))
    #$PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.DAMSEL_IN_DISTRESS), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE), CardPlayer.TOP))

    await CardGameTurnTransitions.begin_game($PlayingField)


func _sample_deck():
    return [
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FINAL_CLOWN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.METAL_SCORPION),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_METAL_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.HONEY_JAR),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FURIOUS_PHANTOM),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNPAID_INTERN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ZANY_ZOMBIE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ZOMBEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BABY_CLOWN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MIME_SUPERIOR),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPARE_BATTERY),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SECOND_COURSE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.WITH_EXTRA_CHEESE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CHICKEN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNDEAD_PIG),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN),
    ]
