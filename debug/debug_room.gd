extends Node2D

const GreedyAIAgent = preload("res://card_game/playing_field/player_agent/greedy_ai_agent/greedy_ai_agent.tscn")
const MonteCarloAIAgent = preload("res://card_game/playing_field/player_agent/monte_carlo_ai_agent/monte_carlo_ai_agent.tscn")
const LookaheadAIAgent = preload("res://card_game/playing_field/player_agent/lookahead_ai_agent/lookahead_ai_agent.tscn")
const NullAIAgent = preload("res://card_game/playing_field/player_agent/null_ai_agent.gd")
const HumanAgent = preload("res://card_game/playing_field/player_agent/human_agent/human_agent.gd")
const VirtualPlayingField = preload("res://card_game/playing_field/virtual_playing_field/virtual_playing_field.tscn")


func _ready():
    #_load_all_cards()  # Comment when not using; it's slow.
    _debug_interactive_game()
    #_debug_batch_game()


func _debug_batch_game() -> void:
    var top_winners = 0
    var bottom_winners = 0
    for i in range(100):
        print(i)
        var virtual_playing_field = VirtualPlayingField.instantiate()
        virtual_playing_field.get_deck(CardPlayer.BOTTOM).cards().replace_cards(_sample_deck())
        virtual_playing_field.get_deck(CardPlayer.TOP).cards().replace_cards(_sample_deck())
        virtual_playing_field.get_deck(CardPlayer.BOTTOM).cards().shuffle()
        virtual_playing_field.get_deck(CardPlayer.TOP).cards().shuffle()
        virtual_playing_field.replace_player_agent(CardPlayer.TOP, GreedyAIAgent.instantiate())
        virtual_playing_field.replace_player_agent(CardPlayer.BOTTOM, GreedyAIAgent.instantiate())
        var winner = await CardGameTurnTransitions.play_full_game(virtual_playing_field)
        if winner == CardPlayer.TOP:
            top_winners += 1
        else:
            bottom_winners += 1
        virtual_playing_field.free()
    print("Top: %s, Bottom: %s" % [top_winners, bottom_winners])


func _debug_interactive_game():
    var ai_priorities = LookaheadPriorities.new({
        LookaheadPriorities.UNDEAD: 1.0,
        LookaheadPriorities.UNDEAD_DESTRUCTION: 0.2,
        LookaheadPriorities.UNDEAD_BONUS_ATTACK: 0.3,
        LookaheadPriorities.CLOWNING: 0.4,
        LookaheadPriorities.BEDEVILING: 0.2,
        LookaheadPriorities.ROBOTING: 0.1,
        LookaheadPriorities.SPIKY: 0.3,
        LookaheadPriorities.HAND_LIMIT_UP: 0.6,
    })
    var ai = LookaheadAIAgent.instantiate()
    ai.priorities = ai_priorities
    $PlayingField.replace_player_agent(CardPlayer.TOP, ai)

    #$PlayingField.replace_player_agent(CardPlayer.TOP, NullAIAgent.new())
    $PlayingField.replace_player_agent(CardPlayer.BOTTOM, HumanAgent.new())
    #$PlayingField.replace_player_agent(CardPlayer.BOTTOM, GreedyAIAgent.instantiate())
    var bottom_deck = $PlayingField.get_deck(CardPlayer.BOTTOM)
    var top_deck = $PlayingField.get_deck(CardPlayer.TOP)
    bottom_deck.cards().replace_cards(_sample_deck())
    top_deck.cards().replace_cards(_sample_deck())
    bottom_deck.cards().shuffle()
    top_deck.cards().shuffle()

    $PlayingField.turn_number = 10  # Get extra EP :)
    $PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURTLES_UNITE))
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE))
    #$PlayingField.get_hand(CardPlayer.TOP).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.DR_BADGUY_DOOMCAKE))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORDYCEPS), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.MILKMAN_MARAUDER), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE), CardPlayer.TOP))
    #$PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.INVASIVE_PARASITES), CardPlayer.TOP))
    #$PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KIDNAPPING_THE_PRESIDENT), CardPlayer.TOP))
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.NO_HONK_ZONE))

    await CardGameTurnTransitions.play_full_game($PlayingField)
    print("Endgame :)")


func _sample_deck():
    return [
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ZANY_ZOMBIE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FURIOUS_PHANTOM),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CAPTAIN_CIRCLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.DEATH_CYBORG),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.DEATH_CYBORG),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SHELL_SHIELD),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_SHELL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TINY_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORDYCEPS),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MASKED_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORDYCEPS),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORDYCEPS),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.RED_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.WORKER_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.WORKER_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.GOLDEN_ACORN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_MUSHROOM_MAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_MUSHROOM_MAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_ACORN),
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
