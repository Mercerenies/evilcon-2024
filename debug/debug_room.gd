extends Node2D

const MushroomMan = preload("res://card_game/playing_card/cards/mushroom_man.gd")
const PotOfLinguine = preload("res://card_game/playing_card/cards/pot_of_linguine.gd")
const SpikyMushroomMan = preload("res://card_game/playing_card/cards/spiky_mushroom_man.gd")
const TinyTurtle = preload("res://card_game/playing_card/cards/tiny_turtle.gd")
const ZanyZombie = preload("res://card_game/playing_card/cards/zany_zombie.gd")
const SergeantSquare = preload("res://card_game/playing_card/cards/sergeant_square.gd")
const TriangleTrooper = preload("res://card_game/playing_card/cards/triangle_trooper.gd")
const GreedyEnemyAI = preload("res://card_game/playing_field/enemy_ai/greedy_enemy_ai.tscn")


func _ready():
    $PlayingField.replace_enemy_ai(GreedyEnemyAI.instantiate())
    var bottom_deck = $PlayingField.get_deck(CardPlayer.BOTTOM)
    var top_deck = $PlayingField.get_deck(CardPlayer.TOP)
    bottom_deck.cards().replace_cards(_sample_deck())
    top_deck.cards().replace_cards(_sample_deck())
    bottom_deck.cards().shuffle()
    top_deck.cards().shuffle()

    await CardGameTurnTransitions.begin_game($PlayingField)


func _sample_deck():
    return [
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.DEATH_CYBORG),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ROBOT_ASSISTANT),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TODDLER_CLOWN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.HIRED_NINJA),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.IT_WORKER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MIDDLE_MANAGER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.HIRED_NINJA),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PENNE_PIKEMAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.HIRED_NINJA),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PENNE_SHARPSHOOTER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ANCIENT_SCROLL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ANCIENT_SCROLL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PASTA_POWER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.RHOMBUS_RANGER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.RAVIOLI_RUNT),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PASTA_POWER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.POT_OF_LINGUINE),
    ]
