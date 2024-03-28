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
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.CATACOMB_CHARMER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPIKY_MUSHROOM_MAN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TINY_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.TINY_TURTLE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ROBOT_MITE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.METAL_SPIDER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.POWER_SURGE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.REINFORCED_SHELL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.POWER_SURGE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MIRROR_CRYSTAL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PENNE_SHARPSHOOTER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ANCIENT_SCROLL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ANCIENT_SCROLL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PASTA_POWER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.NINJA_ASSASSIN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.MIRROR_CRYSTAL),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.PASTA_POWER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.POT_OF_LINGUINE),
    ]
