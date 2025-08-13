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
        LookaheadPriorities.FARM_RECOVERY: 0.3,
        LookaheadPriorities.RULE_22: 9.0,
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
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.THE_INQUISITOR))
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_CANNOLI))
    #$PlayingField.get_hand(CardPlayer.TOP).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.THE_INQUISITOR))
    #$PlayingField.get_hand(CardPlayer.TOP).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_CANNOLI))
    #$PlayingField.get_hand(CardPlayer.TOP).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.REFRIGERATION))
    #$PlayingField.get_hand(CardPlayer.TOP).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.DUCK))
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.KING_TURTLE))
    #$PlayingField.get_hand(CardPlayer.TOP).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.DR_BADGUY_DOOMCAKE))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.MAXWELL_STERLING), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.MILKMAN_MARAUDER), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.BOTTOM).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY), CardPlayer.BOTTOM))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.THE_MASTERMIME), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.GIGGLES_GALORE), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.CHICKEN), CardPlayer.TOP))
    #$PlayingField.get_minion_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY), CardPlayer.TOP))
    #$PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.INVASIVE_PARASITES), CardPlayer.TOP))
    $PlayingField.get_effect_strip(CardPlayer.TOP).cards().push_card(Card.new(PlayingCardCodex.get_entity(PlayingCardCodex.ID.RULE_22), CardPlayer.TOP))
    #$PlayingField.get_hand(CardPlayer.BOTTOM).cards().push_card(PlayingCardCodex.get_entity(PlayingCardCodex.ID.NO_HONK_ZONE))

    #for card in $PlayingField.get_minion_strip(CardPlayer.TOP).cards().card_array():
    #    card.metadata[CardMeta.MORALE] = 2

    await CardGameTurnTransitions.play_full_game($PlayingField)
    print("Endgame :)")


func _sample_deck():
    return [
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.LITTLE_DICEMAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.THE_KING_OF_CRIME),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SKUNKMAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNPAID_INTERN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BOILING_POT_OF_WATER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.RULE_OF_KNOWLEDGE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TRIANGLE_TROOPER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CORNY_ACORN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TRIANGLE_TROOPER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.POT_OF_LINGUINE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.RULE_22),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TINY_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.GREEDY_GOBLIN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TRIANGLE_TROOPER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PET_COW),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.REGINALD_RANDOLPH),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BABY_CLOWN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.GREEN_DICE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.RED_DICE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.LITTLE_DICEMAN),
    ]

    # return [
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.TREE_NYMPH),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.FANCIFUL_FAIRY),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.DUCK),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.INFERNAL_IMP),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.CHICKEN),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.DUCK),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_SHELL),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.TURKEY),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.SUPER_PLUMBER_BROS),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.ULTIMATE_FUSION),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.RED_TURTLE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.RED_TURTLE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.NEEDLE_STRIKE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.POT_OF_LINGUINE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMANS_BROTHER),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.ALONE_IN_THE_DARK),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.PLUMBERMAN),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.NEEDLE_STRIKE),
    # ]

    # return [
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.GREEN_RANGER),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.GREEN_RANGER),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.GREEN_RANGER),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.HYPERACTIVE_BEE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.HYPERACTIVE_BEE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.HYPERACTIVE_BEE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.ICE_MOTH),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.ICE_MOTH),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.ICE_MOTH),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.TEAM_COBRA),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.TEAM_COBRA),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.TEAM_COBRA),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.POT_OF_LINGUINE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.MILK_DELIVERY),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.PET_COW),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.MILK_DELIVERY),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.SECOND_COURSE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.WITH_EXTRA_CHEESE),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.BOILING_POT_OF_WATER),
    #     PlayingCardCodex.get_entity(PlayingCardCodex.ID.COVER_OF_MOONLIGHT),
    # ]


func _load_all_cards():
    # This is just a quick lint so that Godot has to load all of the
    # cards and make sure variables exist in the code and whatnot.
    # Just checking for typos and obvious stuff :)
    for id in PlayingCardCodex.get_all_ids():
        PlayingCardCodex.get_entity_script(id)


func _on_playing_field_game_ended(winner):
    print(str(winner) + " wins!")
    get_tree().quit()
