extends Node2D

const GreedyAIAgent = preload("res://card_game/playing_field/player_agent/greedy_ai_agent.tscn")
const NullAIAgent = preload("res://card_game/playing_field/player_agent/null_ai_agent.gd")
const HumanAgent = preload("res://card_game/playing_field/player_agent/human_agent.gd")


func _ready():
    #_load_all_cards()  # Comment when not using; it's slow.

    $PlayingField.replace_player_agent(CardPlayer.TOP, GreedyAIAgent.instantiate())
    #$PlayingField.replace_player_agent(CardPlayer.TOP, NullAIAgent.new())
    $PlayingField.replace_player_agent(CardPlayer.BOTTOM, HumanAgent.new())
    #$PlayingField.replace_player_agent(CardPlayer.BOTTOM, GreedyAIAgent.instantiate())
    var bottom_deck = $PlayingField.get_deck(CardPlayer.BOTTOM)
    var top_deck = $PlayingField.get_deck(CardPlayer.TOP)
    bottom_deck.cards().replace_cards(_sample_deck())
    top_deck.cards().replace_cards(_sample_deck())
    bottom_deck.cards().shuffle()
    top_deck.cards().shuffle()

    #$PlayingField.turn_number = 10  # Get extra EP :)
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.LIVESTOCK_DELIVERY))
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

    $PlayingField.begin_game()


func _sample_deck():
    return [
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FARMERS_MARKET),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.LIFE_DRAIN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MYSTERY_BOX),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BRAINWASHING_RAY),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.DUCK),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.VENOMATRIX),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.QUEEN_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ALONE_IN_THE_DARK),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.QUEEN_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORNY_ACORN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TINY_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.WORKER_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CLUELESS_MAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BEEATRICE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SKUNKMAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.WALL_GOLEM),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
    ]


func _load_all_cards():
    # This is just a quick lint so that Godot has to load all of the
    # cards and make sure variables exist in the code and whatnot.
    # Just checking for typos and obvious stuff :)
    for id in PlayingCardCodex.get_all_ids():
        PlayingCardCodex.get_entity_script(id)


func _on_playing_field_game_ended(winner):
    print(str(winner) + " wins!")
    get_tree().quit()
