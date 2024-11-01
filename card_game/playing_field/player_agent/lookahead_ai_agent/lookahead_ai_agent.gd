extends PlayerAgent

# LookaheadAIAgent uses the AI fields on the card type class to
# determine which card is best to play.
#
# Every card type in the AI's hand is given a real-numbered score,
# where a higher score means the card is a better choice to play right
# now.
#
# The general rule is that the score should always translate into Evil
# Points or fort defense. That is:
#
# * Every positive score point on a card should translate to (1) an
#   Evil Point gained, (2) a friendly fort health point gained, or (3)
#   an enemy fort health point lost.
#
# * Every negative score point on a card should translate to (1) an
#   Evil Point spent, (2) a friendly fort health point lost, or (3) an
#   enemy fort health point restored.
#
# * Successfully activating Destiny's Song is worth 1/3 of the enemy's
#   total fort defense, or +20 score.
#
# * Things that are more difficult to quantify use a best-effort
#   basis. Different variants of the AI may have different priorities.
#   For instance, an AI who knows he has Destiny's Song in his deck
#   will consider drawing extra cards to be far more valuable than an
#   AI who is just trying to resurrect UNDEAD Minions.
#
# All of an agent's priorities and goals can be customized by the
# LookaheadPriorities class. Several of them (such as the value of
# spending Evil Points) should probably not be changed, but others are
# more difficult to quantify objectively, and different strategies may
# require different weights.

var priorities

# Sentinel value for the "End Turn" action
const END_OF_TURN = &"LookaheadAIAgent.END_OF_TURN"


func _init(priorities = null) -> void:
    self.priorities = priorities if priorities != null else LookaheadPriorities.new({})


func run_one_turn(playing_field) -> void:
    while true:
        await playing_field.with_animation(func(_animation_layer):
            $NextActionTimer.start()
            await $NextActionTimer.timeout)
        var legal_moves = _get_legal_moves(playing_field)
        var move_values = legal_moves.map(func(move): return _score_of_move(playing_field, move))
        _debug_print_moves(legal_moves, move_values)
        var indices = range(len(legal_moves))
        var best_move_index = Util.max_on(indices, func(i): return move_values[i])
        var best_move = legal_moves[best_move_index]
        if not (best_move is CardType):
            break  # Turn is done
        await CardGameApi.play_card_from_hand(playing_field, controlled_player, best_move)


func _debug_print_moves(legal_moves, move_values) -> void:
    # Debug code to print out all options and show us the perceived
    # value of each.
    print ("== AI TURN ==")
    var moves = Util.zip(legal_moves, move_values)
    moves.sort_custom(func(a, b): return a.second > b.second)
    for m in moves:
        var move_name = m.first if m.first is StringName else m.first.get_title()
        print(move_name, "   ", m.second)


func _get_legal_moves(playing_field):
    var hand = playing_field.get_hand(controlled_player)
    var legal_moves = hand.cards().card_array().filter(
        func(card_type): return card_type.can_play(playing_field, controlled_player)
    )
    legal_moves.push_back(END_OF_TURN)
    return legal_moves


func _score_of_move(playing_field, move) -> float:
    if move is StringName and move == END_OF_TURN:
        return _end_of_turn_score(playing_field)
    else:
        return move.ai_get_score(playing_field, controlled_player, priorities)


func _end_of_turn_score(playing_field) -> float:
    # The "value" of the End of Turn action is always non-positive and
    # represents the opportunity cost paid by REFUSING to play any
    # more cards.
    var evil_points_remaining = playing_field.get_stats(controlled_player).evil_points
    var cards_in_hand = playing_field.get_hand(controlled_player).cards().card_count()
    var max_hand_size = StatsCalculator.get_hand_limit(playing_field, controlled_player)
    var cards_per_turn = StatsCalculator.get_cards_per_turn(playing_field, controlled_player)
    # If we end our turn now, this is the number of draws we will
    # "miss out on" by hitting our hand limit next turn.
    var excess_cards_next_turn = (cards_in_hand + cards_per_turn) - max_hand_size

    var score = - evil_points_remaining * priorities.of(LookaheadPriorities.EVIL_POINT_OPPORTUNITY)
    if excess_cards_next_turn > 0:
        score -= priorities.of(LookaheadPriorities.FIRST_DRAW)
        score -= (excess_cards_next_turn - 1) * priorities.of(LookaheadPriorities.NORMAL_DRAW)
    return score


func on_end_turn_button_pressed(_playing_field) -> void:
    # AI-controlled agent; ignore user input.
    pass


func suppresses_input() -> bool:
    return true
