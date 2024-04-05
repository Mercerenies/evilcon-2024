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
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMANS_BROTHER))
    #$PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.COVER_OF_MOONLIGHT), CardPlayer.TOP))

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
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.STREET_MIME),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MASKED_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN),
    ]
